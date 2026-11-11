#include <cmath>
#include <limits>

#include "internal.hpp"

namespace noosh24 {

namespace {

Headers lowered(const Headers& headers)
{
    Headers out;
    for (const auto& [name, value] : headers) {
        out[detail::lower(name)] = value;
    }
    return out;
}

template <class E>
[[noreturn]] void raise(int status, std::optional<std::string> code, std::string message, const Headers& headers,
                        const std::string& body)
{
    throw E(status, std::move(code), std::move(message), headers, body);
}

}

ApiError::ApiError(int status, std::optional<std::string> code, std::string message, Headers headers, std::string body)
    : Error{message},
      status_{status},
      code_{std::move(code)},
      message_{std::move(message)},
      headers_{lowered(headers)},
      body_{std::move(body)}
{
}

std::optional<int> RateLimitError::retry_after() const
{
    auto it = headers().find("retry-after");
    if (it == headers().end()) {
        return std::nullopt;
    }
    auto seconds = detail::parse_number(it->second);
    if (!seconds) {
        return std::nullopt;
    }
    double value = std::trunc(*seconds);
    if (value <= 0) {
        return 0;
    }
    if (value >= static_cast<double>(std::numeric_limits<int>::max())) {
        return std::numeric_limits<int>::max();
    }
    return static_cast<int>(value);
}

namespace detail {

void throw_api_error(int status, const Headers& headers, const std::string& body)
{
    std::optional<std::string> code;
    std::string message;
    json parsed = json::parse(body, nullptr, false);
    if (parsed.is_object()) {
        auto error = parsed.find("error");
        if (error != parsed.end() && error->is_string()) {
            code = error->get<std::string>();
        }
        auto text = parsed.find("message");
        if (text != parsed.end() && text->is_string()) {
            message = text->get<std::string>();
        }
    }
    if (message.empty()) {
        message = code ? *code : "HTTP " + std::to_string(status);
    }
    const std::string c = code.value_or("");
    if (c == "validation_error") raise<ValidationError>(status, code, message, headers, body);
    if (c == "no_api_key") raise<NoApiKeyError>(status, code, message, headers, body);
    if (c == "invalid_api_key") raise<InvalidApiKeyError>(status, code, message, headers, body);
    if (c == "insufficient_scope") raise<InsufficientScopeError>(status, code, message, headers, body);
    if (c == "module_not_enabled") raise<ModuleNotEnabledError>(status, code, message, headers, body);
    if (c == "venue_suspended") raise<VenueSuspendedError>(status, code, message, headers, body);
    if (c == "not_your_reservation") raise<NotYourReservationError>(status, code, message, headers, body);
    if (c == "not_found") raise<NotFoundError>(status, code, message, headers, body);
    if (c == "table_not_found") raise<TableNotFoundError>(status, code, message, headers, body);
    if (c == "table_taken") raise<TableTakenError>(status, code, message, headers, body);
    if (c == "cannot_cancel") raise<CannotCancelError>(status, code, message, headers, body);
    if (c == "outside_hours") raise<OutsideHoursError>(status, code, message, headers, body);
    if (c == "in_the_past") raise<InThePastError>(status, code, message, headers, body);
    if (c == "table_too_small") raise<TableTooSmallError>(status, code, message, headers, body);
    if (c == "rate_limit_exceeded") raise<RateLimitError>(status, code, message, headers, body);
    if (c == "temporarily_unavailable") raise<TemporarilyUnavailableError>(status, code, message, headers, body);
    switch (status) {
    case 400:
        raise<ValidationError>(status, code, message, headers, body);
    case 401:
        raise<AuthenticationError>(status, code, message, headers, body);
    case 403:
        raise<PermissionDeniedError>(status, code, message, headers, body);
    case 404:
        raise<NotFoundError>(status, code, message, headers, body);
    case 409:
        raise<ConflictError>(status, code, message, headers, body);
    case 422:
        raise<UnprocessableError>(status, code, message, headers, body);
    case 429:
        raise<RateLimitError>(status, code, message, headers, body);
    default:
        break;
    }
    if (status >= 500) {
        raise<ServerError>(status, code, message, headers, body);
    }
    raise<ApiError>(status, code, message, headers, body);
}

}

}
