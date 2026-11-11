#pragma once

#include <chrono>
#include <functional>
#include <memory>
#include <string>
#include <string_view>

#include <noosh24/models.hpp>
#include <noosh24/resources.hpp>
#include <noosh24/transport.hpp>

namespace noosh24 {

inline constexpr std::string_view default_base_url = "https://open-api.noosh24.com/v1";

struct ClientOptions {
    std::string base_url{default_base_url};
    std::chrono::milliseconds timeout{std::chrono::seconds{30}};
    int max_retries = 2;
    std::string user_agent{};
    std::shared_ptr<Transport> transport{};
    std::function<void(std::chrono::milliseconds)> sleep{};
};

class Client {
public:
    explicit Client(std::string_view api_key, ClientOptions options = {});
    explicit Client(const char* api_key, ClientOptions options = {});
    Client(Client&&) noexcept;
    Client& operator=(Client&&) noexcept;
    Client(const Client&) = delete;
    Client& operator=(const Client&) = delete;
    ~Client();

    [[nodiscard]] Whoami whoami() const;

    [[nodiscard]] Menu menu() const noexcept;
    [[nodiscard]] Reservations reservations() const noexcept;
    [[nodiscard]] Orders orders() const noexcept;
    [[nodiscard]] Payments payments() const noexcept;
    [[nodiscard]] Tables tables() const noexcept;
    [[nodiscard]] Customers customers() const noexcept;
    [[nodiscard]] Loyalty loyalty() const noexcept;
    [[nodiscard]] Stock stock() const noexcept;
    [[nodiscard]] Reviews reviews() const noexcept;

private:
    std::unique_ptr<detail::Core> core_{};
};

}
