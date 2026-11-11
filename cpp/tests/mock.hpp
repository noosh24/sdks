#pragma once

#include <algorithm>
#include <cctype>
#include <chrono>
#include <deque>
#include <exception>
#include <map>
#include <memory>
#include <stdexcept>
#include <string>
#include <utility>
#include <variant>
#include <vector>

#include <gtest/gtest.h>
#include <nlohmann/json.hpp>

#include <noosh24/noosh24.hpp>

namespace testing_support {

using nlohmann::json;
using QueryMap = std::map<std::string, std::vector<std::string>>;

class MockTransport : public noosh24::Transport {
public:
    MockTransport& reply(int status, const json& body, noosh24::Headers headers = {})
    {
        queue_.emplace_back(noosh24::Response{status, std::move(headers), body.dump()});
        return *this;
    }

    MockTransport& raw(int status, std::string text)
    {
        queue_.emplace_back(noosh24::Response{status, {}, std::move(text)});
        return *this;
    }

    template <class E>
    MockTransport& fail(E error)
    {
        queue_.emplace_back(std::make_exception_ptr(std::move(error)));
        return *this;
    }

    noosh24::Response send(const noosh24::Request& request) override
    {
        requests.push_back(request);
        if (queue_.empty()) {
            throw std::logic_error("No response queued for " + request.method + " " + request.url);
        }
        auto next = std::move(queue_.front());
        queue_.pop_front();
        if (auto* error = std::get_if<std::exception_ptr>(&next)) {
            std::rethrow_exception(*error);
        }
        return std::get<noosh24::Response>(std::move(next));
    }

    [[nodiscard]] const noosh24::Request& last() const { return requests.back(); }

    std::vector<noosh24::Request> requests;

private:
    std::deque<std::variant<noosh24::Response, std::exception_ptr>> queue_;
};

inline std::string decode(std::string_view text)
{
    std::string out;
    for (std::size_t i = 0; i < text.size(); ++i) {
        if (text[i] == '%' && i + 2 < text.size()) {
            out += static_cast<char>(std::stoi(std::string(text.substr(i + 1, 2)), nullptr, 16));
            i += 2;
        } else if (text[i] == '+') {
            out += ' ';
        } else {
            out += text[i];
        }
    }
    return out;
}

inline std::string path_of(const std::string& url)
{
    auto scheme = url.find("://");
    auto start = url.find('/', scheme == std::string::npos ? 0 : scheme + 3);
    auto end = url.find('?', start);
    return url.substr(start, end == std::string::npos ? std::string::npos : end - start);
}

inline QueryMap query_of(const std::string& url)
{
    QueryMap out;
    auto mark = url.find('?');
    if (mark == std::string::npos) {
        return out;
    }
    std::string_view rest = std::string_view(url).substr(mark + 1);
    while (!rest.empty()) {
        auto amp = rest.find('&');
        auto pair = rest.substr(0, amp);
        auto eq = pair.find('=');
        out[decode(pair.substr(0, eq))].push_back(eq == std::string_view::npos ? "" : decode(pair.substr(eq + 1)));
        if (amp == std::string_view::npos) {
            break;
        }
        rest.remove_prefix(amp + 1);
    }
    return out;
}

inline std::string header(const noosh24::Request& request, std::string_view name)
{
    std::string wanted(name);
    for (auto& c : wanted) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    for (const auto& [key, value] : request.headers) {
        std::string lowered = key;
        for (auto& c : lowered) {
            c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        }
        if (lowered == wanted) {
            return value;
        }
    }
    return {};
}

inline bool has_header(const noosh24::Request& request, std::string_view name)
{
    for (const auto& [key, value] : request.headers) {
        if (key.size() == name.size() &&
            std::equal(key.begin(), key.end(), name.begin(), [](char a, char b) {
                return std::tolower(static_cast<unsigned char>(a)) == std::tolower(static_cast<unsigned char>(b));
            })) {
            return true;
        }
    }
    return false;
}

inline json page(const json& items, int total, int limit = 20, int offset = 0)
{
    return json{{"data", {{"items", items}, {"total", total}, {"limit", limit}, {"offset", offset}}}};
}

inline json body_of(const noosh24::Request& request)
{
    return json::parse(request.body.value_or("null"));
}

class ClientTest : public ::testing::Test {
protected:
    noosh24::Client make(noosh24::ClientOptions options = {})
    {
        options.transport = http;
        options.sleep = [this](std::chrono::milliseconds wait) { sleeps.push_back(wait); };
        return noosh24::Client{"nsk_test_123", std::move(options)};
    }

    std::shared_ptr<MockTransport> http = std::make_shared<MockTransport>();
    std::vector<std::chrono::milliseconds> sleeps;
};

}
