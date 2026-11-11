#pragma once

#include <chrono>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include <noosh24/errors.hpp>

namespace noosh24 {

struct Request {
    std::string method{};
    std::string url{};
    std::vector<std::pair<std::string, std::string>> headers{};
    std::optional<std::string> body{};
    std::chrono::milliseconds timeout{std::chrono::seconds{30}};
};

struct Response {
    int status = 0;
    Headers headers{};
    std::string body{};
};

class Transport {
public:
    Transport() = default;
    Transport(const Transport&) = delete;
    Transport& operator=(const Transport&) = delete;
    virtual ~Transport() = default;

    virtual Response send(const Request& request) = 0;
};

class CurlTransport final : public Transport {
public:
    CurlTransport();
    ~CurlTransport() override;

    Response send(const Request& request) override;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_{};
};

}
