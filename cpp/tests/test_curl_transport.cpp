#if !defined(_WIN32)

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <csignal>
#include <thread>

#include "mock.hpp"

using namespace std::chrono_literals;

namespace {

int listen_socket(int& port)
{
    int fd = ::socket(AF_INET, SOCK_STREAM, 0);
    int yes = 1;
    ::setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof yes);
    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = 0;
    if (::bind(fd, reinterpret_cast<sockaddr*>(&address), sizeof address) != 0 || ::listen(fd, 4) != 0) {
        ::close(fd);
        throw std::runtime_error("could not listen on loopback");
    }
    socklen_t length = sizeof address;
    ::getsockname(fd, reinterpret_cast<sockaddr*>(&address), &length);
    port = ntohs(address.sin_port);
    return fd;
}

class LoopbackServer {
public:
    explicit LoopbackServer(std::optional<std::string> response) : response_{std::move(response)}
    {
        std::signal(SIGPIPE, SIG_IGN);
        fd_ = listen_socket(port_);
        thread_ = std::thread([this] { serve(); });
    }

    LoopbackServer(const LoopbackServer&) = delete;
    LoopbackServer& operator=(const LoopbackServer&) = delete;

    ~LoopbackServer()
    {
        if (thread_.joinable()) {
            thread_.join();
        }
        ::close(fd_);
    }

    [[nodiscard]] std::string url(std::string_view path) const
    {
        return "http://127.0.0.1:" + std::to_string(port_) + std::string(path);
    }

    std::string received()
    {
        if (thread_.joinable()) {
            thread_.join();
        }
        return received_;
    }

private:
    void serve()
    {
        int client = ::accept(fd_, nullptr, nullptr);
        if (client < 0) {
            return;
        }
        char buffer[4096];
        std::size_t expected = std::string::npos;
        while (true) {
            auto n = ::recv(client, buffer, sizeof buffer, 0);
            if (n <= 0) {
                break;
            }
            received_.append(buffer, static_cast<std::size_t>(n));
            auto end = received_.find("\r\n\r\n");
            if (end != std::string::npos && expected == std::string::npos) {
                std::size_t length = 0;
                std::string head = received_.substr(0, end);
                for (auto& c : head) {
                    c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
                }
                auto at = head.find("content-length:");
                if (at != std::string::npos) {
                    length = std::stoul(head.substr(at + 15));
                }
                expected = end + 4 + length;
            }
            if (response_ && expected != std::string::npos && received_.size() >= expected) {
                break;
            }
        }
        if (response_) {
            ::send(client, response_->data(), response_->size(), 0);
        }
        ::close(client);
    }

    std::optional<std::string> response_;
    int fd_ = -1;
    int port_ = 0;
    std::thread thread_;
    std::string received_;
};

std::string http_response(int status, const std::string& reason, const std::string& body, const std::string& extra = {})
{
    return "HTTP/1.1 " + std::to_string(status) + " " + reason + "\r\nContent-Type: application/json\r\n" + extra +
           "Content-Length: " + std::to_string(body.size()) + "\r\nConnection: close\r\n\r\n" + body;
}

noosh24::Request request(std::string method, std::string url, std::optional<std::string> body = std::nullopt)
{
    noosh24::Request out;
    out.method = std::move(method);
    out.url = std::move(url);
    out.headers = {{"Authorization", "Bearer nsk_local"}, {"Accept", "application/json"}};
    if (body) {
        out.headers.emplace_back("Content-Type", "application/json");
    }
    out.body = std::move(body);
    out.timeout = 5s;
    return out;
}

}

TEST(CurlTransport, GetSendsHeadersAndReadsTheResponse)
{
    LoopbackServer server{http_response(200, "OK", R"({"data":{}})", "Retry-After: 3\r\nX-Multi: a\r\nX-Multi: b\r\n")};
    noosh24::CurlTransport transport;

    auto response = transport.send(request("GET", server.url("/v1/whoami?x=1")));

    EXPECT_EQ(response.status, 200);
    EXPECT_EQ(response.body, R"({"data":{}})");
    EXPECT_EQ(response.headers.at("retry-after"), "3");
    EXPECT_EQ(response.headers.at("x-multi"), "a, b");
    auto received = server.received();
    EXPECT_TRUE(received.starts_with("GET /v1/whoami?x=1 HTTP/1.1\r\n")) << received;
    EXPECT_NE(received.find("Authorization: Bearer nsk_local\r\n"), std::string::npos);
    EXPECT_NE(received.find("Accept: application/json\r\n"), std::string::npos);
    EXPECT_EQ(received.find("Content-Type"), std::string::npos);
}

TEST(CurlTransport, PostSendsTheJsonBody)
{
    LoopbackServer server{http_response(201, "Created", R"({"data":{"id":"r1"}})")};
    noosh24::CurlTransport transport;
    std::string body = R"({"guestName":"Aysel Məmmədova"})";

    auto response = transport.send(request("POST", server.url("/v1/reservations"), body));

    EXPECT_EQ(response.status, 201);
    auto received = server.received();
    EXPECT_TRUE(received.starts_with("POST /v1/reservations HTTP/1.1\r\n"));
    EXPECT_NE(received.find("Content-Type: application/json\r\n"), std::string::npos);
    EXPECT_NE(received.find("Content-Length: " + std::to_string(body.size()) + "\r\n"), std::string::npos);
    EXPECT_TRUE(received.ends_with("\r\n\r\n" + body));
}

TEST(CurlTransport, PostWithoutBodySendsNoContentType)
{
    LoopbackServer server{http_response(200, "OK", R"({"data":{}})")};
    noosh24::CurlTransport transport;

    (void)transport.send(request("POST", server.url("/v1/reservations/r1/cancel")));

    auto received = server.received();
    EXPECT_TRUE(received.starts_with("POST /v1/reservations/r1/cancel HTTP/1.1\r\n"));
    EXPECT_NE(received.find("Content-Length: 0\r\n"), std::string::npos);
    EXPECT_EQ(received.find("Content-Type"), std::string::npos);
}

TEST(CurlTransport, RefusedConnectionIsAConnectionError)
{
    int port = 0;
    ::close(listen_socket(port));
    noosh24::CurlTransport transport;

    try {
        (void)transport.send(request("GET", "http://127.0.0.1:" + std::to_string(port) + "/v1/whoami"));
        FAIL() << "expected ConnectionError";
    } catch (const noosh24::TimeoutError&) {
        FAIL() << "expected a plain ConnectionError";
    } catch (const noosh24::ConnectionError& error) {
        EXPECT_TRUE(std::string(error.what()).starts_with("Could not reach the Noosh24 API: "));
    }
}

TEST(CurlTransport, SlowServerIsATimeout)
{
    LoopbackServer server{std::nullopt};
    noosh24::CurlTransport transport;
    auto slow = request("GET", server.url("/v1/whoami"));
    slow.timeout = 200ms;

    try {
        (void)transport.send(slow);
        FAIL() << "expected TimeoutError";
    } catch (const noosh24::TimeoutError& error) {
        EXPECT_STREQ(error.what(), "Request timed out after 0.2 s");
    }
}

TEST(CurlTransport, ClientWorksEndToEnd)
{
    LoopbackServer server{http_response(
        200, "OK", R"({"data":{"restaurant":{"id":"r1","name":"Masago","slug":"masago"},"brandNew":true}})")};
    noosh24::Client client{"nsk_local", {.base_url = server.url("/v1/")}};

    auto me = client.whoami();

    EXPECT_EQ(me.restaurant->name, "Masago");
    auto received = server.received();
    EXPECT_TRUE(received.starts_with("GET /v1/whoami HTTP/1.1\r\n"));
    EXPECT_NE(received.find("User-Agent: noosh24-cpp/" + std::string(noosh24::version) + "\r\n"), std::string::npos);
    EXPECT_NE(received.find("Authorization: Bearer nsk_local\r\n"), std::string::npos);
}

#endif
