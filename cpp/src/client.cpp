#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <thread>

#include "internal.hpp"
#include "noosh24/version.hpp"

namespace noosh24 {

namespace detail {

namespace {

constexpr double max_retry_wait = 60.0;

std::chrono::milliseconds millis(double seconds)
{
    return std::chrono::milliseconds{static_cast<std::int64_t>(std::llround(seconds * 1000.0))};
}

std::chrono::milliseconds backoff(int attempt)
{
    return millis(std::min(8.0, 0.5 * std::pow(2.0, attempt)));
}

bool retry_status(int status)
{
    return status == 429 || status == 502 || status == 503 || status == 504;
}

std::optional<std::chrono::milliseconds> retry_wait(const Response& response, int attempt)
{
    if (!retry_status(response.status)) {
        return std::nullopt;
    }
    auto header = response.headers.find("retry-after");
    if (header == response.headers.end()) {
        return backoff(attempt);
    }
    auto seconds = parse_number(header->second);
    if (!seconds) {
        return backoff(attempt);
    }
    double wait = std::max(0.0, *seconds);
    if (wait > max_retry_wait) {
        return std::nullopt;
    }
    return millis(wait);
}

json decode(const Response& response)
{
    if (response.body.empty()) {
        return nullptr;
    }
    json parsed = json::parse(response.body, nullptr, false);
    if (parsed.is_discarded()) {
        throw ApiError(response.status, std::nullopt, "The API answered with a body that is not JSON", response.headers,
                       response.body);
    }
    if (!parsed.is_object() || !parsed.contains("data")) {
        throw ApiError(response.status, std::nullopt, "The API answered without a \"data\" field", response.headers,
                       response.body);
    }
    return std::move(parsed["data"]);
}

}

Core::Core(std::string api_key, ClientOptions options)
    : api_key_{std::move(api_key)},
      base_url_{std::move(options.base_url)},
      timeout_{options.timeout},
      max_retries_{std::max(0, options.max_retries)},
      transport_{std::move(options.transport)},
      sleep_{std::move(options.sleep)}
{
    while (!base_url_.empty() && base_url_.back() == '/') {
        base_url_.pop_back();
    }
    if (base_url_.empty()) {
        base_url_ = std::string(default_base_url);
    }
    std::string agent = "noosh24-cpp/" + std::string(version);
    user_agent_ = options.user_agent.empty() ? agent : options.user_agent + " " + agent;
    if (!transport_) {
        transport_ = std::make_shared<CurlTransport>();
    }
    if (!sleep_) {
        sleep_ = [](std::chrono::milliseconds wait) { std::this_thread::sleep_for(wait); };
    }
}

Result Core::request(std::string_view method, std::string_view path, const Query& query,
                     const std::optional<std::string>& body, bool retryable)
{
    Request request;
    request.method = std::string(method);
    request.url = base_url_ + std::string(path) + encode_query(query);
    request.headers = {
        {"Authorization", "Bearer " + api_key_},
        {"Accept", "application/json"},
        {"User-Agent", user_agent_},
    };
    if (body) {
        request.headers.emplace_back("Content-Type", "application/json");
        request.body = *body;
    }
    request.timeout = timeout_;

    int attempt = 0;
    while (true) {
        Response response;
        try {
            response = transport_->send(request);
        } catch (const ConnectionError&) {
            if (retryable && attempt < max_retries_) {
                sleep_(backoff(attempt));
                ++attempt;
                continue;
            }
            throw;
        }
        Headers headers;
        for (auto& [name, value] : response.headers) {
            headers[lower(name)] = std::move(value);
        }
        response.headers = std::move(headers);

        if (response.status >= 200 && response.status < 300) {
            return Result{response.status, decode(response)};
        }
        auto wait = retry_wait(response, attempt);
        if (retryable && attempt < max_retries_ && wait) {
            sleep_(*wait);
            ++attempt;
            continue;
        }
        throw_api_error(response.status, response.headers, response.body);
    }
}

}

Client::Client(std::string_view api_key, ClientOptions options)
{
    auto key = detail::trim(api_key);
    if (key.empty()) {
        throw std::invalid_argument("An API key is required");
    }
    core_ = std::make_unique<detail::Core>(std::string(key), std::move(options));
}

Client::Client(const char* api_key, ClientOptions options)
    : Client{api_key == nullptr ? std::string_view{} : std::string_view{api_key}, std::move(options)}
{
}

Client::Client(Client&&) noexcept = default;
Client& Client::operator=(Client&&) noexcept = default;
Client::~Client() = default;

Whoami Client::whoami() const
{
    return detail::build<Whoami>(core_->request("GET", "/whoami").data);
}

Menu Client::menu() const noexcept
{
    return Menu{*core_};
}

Reservations Client::reservations() const noexcept
{
    return Reservations{*core_};
}

Orders Client::orders() const noexcept
{
    return Orders{*core_};
}

Payments Client::payments() const noexcept
{
    return Payments{*core_};
}

Tables Client::tables() const noexcept
{
    return Tables{*core_};
}

Customers Client::customers() const noexcept
{
    return Customers{*core_};
}

Loyalty Client::loyalty() const noexcept
{
    return Loyalty{*core_};
}

Stock Client::stock() const noexcept
{
    return Stock{*core_};
}

Reviews Client::reviews() const noexcept
{
    return Reviews{*core_};
}

}
