#include <array>
#include <functional>
#include <memory>
#include <mutex>
#include <vector>

#include <curl/curl.h>

#include "internal.hpp"

namespace noosh24 {

namespace {

struct Global {
    Global() { curl_global_init(CURL_GLOBAL_DEFAULT); }
    ~Global() { curl_global_cleanup(); }
    Global(const Global&) = delete;
    Global& operator=(const Global&) = delete;
};

void ensure_global()
{
    static Global global;
}

struct Received {
    std::string body;
    Headers headers;
};

std::size_t on_body(char* data, std::size_t size, std::size_t count, void* user)
{
    auto* received = static_cast<Received*>(user);
    received->body.append(data, size * count);
    return size * count;
}

std::size_t on_header(char* data, std::size_t size, std::size_t count, void* user)
{
    auto* received = static_cast<Received*>(user);
    std::string_view line(data, size * count);
    if (line.starts_with("HTTP/")) {
        received->headers.clear();
        return size * count;
    }
    auto colon = line.find(':');
    if (colon != std::string_view::npos) {
        auto name = detail::lower(detail::trim(line.substr(0, colon)));
        auto value = std::string(detail::trim(line.substr(colon + 1)));
        if (!name.empty()) {
            auto [it, inserted] = received->headers.emplace(name, value);
            if (!inserted) {
                it->second += ", " + value;
            }
        }
    }
    return size * count;
}

struct HeaderList {
    curl_slist* headers = nullptr;
    HeaderList() = default;
    HeaderList(const HeaderList&) = delete;
    HeaderList& operator=(const HeaderList&) = delete;
    ~HeaderList() { curl_slist_free_all(headers); }

    void add(const std::string& header)
    {
        curl_slist* next = curl_slist_append(headers, header.c_str());
        if (next == nullptr) {
            throw ConnectionError("Could not reach the Noosh24 API: out of memory");
        }
        headers = next;
    }
};

}

struct CurlTransport::Impl {
    CURLSH* share = nullptr;
    std::array<std::mutex, CURL_LOCK_DATA_LAST> locks;
    std::mutex pool_lock;
    std::vector<CURL*> idle;

    CURL* acquire()
    {
        {
            std::lock_guard guard{pool_lock};
            if (!idle.empty()) {
                CURL* handle = idle.back();
                idle.pop_back();
                return handle;
            }
        }
        return curl_easy_init();
    }

    void release(CURL* handle)
    {
        curl_easy_reset(handle);
        std::lock_guard guard{pool_lock};
        idle.push_back(handle);
    }

    static void lock(CURL*, curl_lock_data data, curl_lock_access, void* user)
    {
        static_cast<Impl*>(user)->locks[static_cast<std::size_t>(data)].lock();
    }

    static void unlock(CURL*, curl_lock_data data, void* user)
    {
        static_cast<Impl*>(user)->locks[static_cast<std::size_t>(data)].unlock();
    }
};

CurlTransport::CurlTransport() : impl_{std::make_unique<Impl>()}
{
    ensure_global();
    impl_->share = curl_share_init();
    if (impl_->share != nullptr) {
        curl_share_setopt(impl_->share, CURLSHOPT_LOCKFUNC, &Impl::lock);
        curl_share_setopt(impl_->share, CURLSHOPT_UNLOCKFUNC, &Impl::unlock);
        curl_share_setopt(impl_->share, CURLSHOPT_USERDATA, impl_.get());
        curl_share_setopt(impl_->share, CURLSHOPT_SHARE, CURL_LOCK_DATA_DNS);
        curl_share_setopt(impl_->share, CURLSHOPT_SHARE, CURL_LOCK_DATA_SSL_SESSION);
    }
}

CurlTransport::~CurlTransport()
{
    if (!impl_) {
        return;
    }
    for (CURL* handle : impl_->idle) {
        curl_easy_cleanup(handle);
    }
    if (impl_->share != nullptr) {
        curl_share_cleanup(impl_->share);
    }
}

Response CurlTransport::send(const Request& request)
{
    std::unique_ptr<CURL, std::function<void(CURL*)>> handle{impl_->acquire(),
                                                              [this](CURL* used) { impl_->release(used); }};
    if (!handle) {
        throw ConnectionError("Could not reach the Noosh24 API: curl_easy_init failed");
    }
    CURL* h = handle.get();
    HeaderList easy;
    Received received;
    std::array<char, CURL_ERROR_SIZE> error{};

    curl_easy_setopt(h, CURLOPT_URL, request.url.c_str());
    curl_easy_setopt(h, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(h, CURLOPT_FOLLOWLOCATION, 0L);
    curl_easy_setopt(h, CURLOPT_ACCEPT_ENCODING, "");
    curl_easy_setopt(h, CURLOPT_TIMEOUT_MS, static_cast<long>(request.timeout.count()));
    curl_easy_setopt(h, CURLOPT_ERRORBUFFER, error.data());
    curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, &on_body);
    curl_easy_setopt(h, CURLOPT_WRITEDATA, &received);
    curl_easy_setopt(h, CURLOPT_HEADERFUNCTION, &on_header);
    curl_easy_setopt(h, CURLOPT_HEADERDATA, &received);
    if (impl_->share != nullptr) {
        curl_easy_setopt(h, CURLOPT_SHARE, impl_->share);
    }

    bool content_type = false;
    for (const auto& [name, value] : request.headers) {
        if (detail::lower(name) == "content-type") {
            content_type = true;
        }
        easy.add(name + ": " + value);
    }
    easy.add("Expect:");

    const std::string& body = request.body ? *request.body : std::string{};
    if (request.method == "GET") {
        curl_easy_setopt(h, CURLOPT_HTTPGET, 1L);
    } else {
        if (request.method == "POST") {
            curl_easy_setopt(h, CURLOPT_POST, 1L);
        } else {
            curl_easy_setopt(h, CURLOPT_CUSTOMREQUEST, request.method.c_str());
        }
        if (request.body || request.method == "POST") {
            curl_easy_setopt(h, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(body.size()));
            curl_easy_setopt(h, CURLOPT_POSTFIELDS, body.c_str());
        }
        if (!content_type) {
            easy.add("Content-Type:");
        }
    }
    curl_easy_setopt(h, CURLOPT_HTTPHEADER, easy.headers);

    CURLcode code = curl_easy_perform(h);
    if (code == CURLE_OPERATION_TIMEDOUT) {
        throw TimeoutError("Request timed out after " +
                           detail::format_number(static_cast<double>(request.timeout.count()) / 1000.0) + " s");
    }
    if (code != CURLE_OK) {
        std::string reason = error[0] != '\0' ? std::string(error.data()) : std::string(curl_easy_strerror(code));
        throw ConnectionError("Could not reach the Noosh24 API: " + reason);
    }
    long status = 0;
    curl_easy_getinfo(h, CURLINFO_RESPONSE_CODE, &status);
    return Response{static_cast<int>(status), std::move(received.headers), std::move(received.body)};
}

}
