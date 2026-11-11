#pragma once

#include <map>
#include <optional>
#include <stdexcept>
#include <string>

namespace noosh24 {

using Headers = std::map<std::string, std::string>;

class Error : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

class ConnectionError : public Error {
public:
    using Error::Error;
};

class TimeoutError : public ConnectionError {
public:
    using ConnectionError::ConnectionError;
};

class ApiError : public Error {
public:
    ApiError(int status, std::optional<std::string> code, std::string message, Headers headers = {}, std::string body = {});

    [[nodiscard]] int status() const noexcept { return status_; }
    [[nodiscard]] const std::optional<std::string>& code() const noexcept { return code_; }
    [[nodiscard]] const std::string& message() const noexcept { return message_; }
    [[nodiscard]] const Headers& headers() const noexcept { return headers_; }
    [[nodiscard]] const std::string& body() const noexcept { return body_; }

private:
    int status_;
    std::optional<std::string> code_;
    std::string message_;
    Headers headers_;
    std::string body_;
};

class ValidationError : public ApiError {
public:
    using ApiError::ApiError;
};

class AuthenticationError : public ApiError {
public:
    using ApiError::ApiError;
};

class NoApiKeyError : public AuthenticationError {
public:
    using AuthenticationError::AuthenticationError;
};

class InvalidApiKeyError : public AuthenticationError {
public:
    using AuthenticationError::AuthenticationError;
};

class PermissionDeniedError : public ApiError {
public:
    using ApiError::ApiError;
};

class InsufficientScopeError : public PermissionDeniedError {
public:
    using PermissionDeniedError::PermissionDeniedError;
};

class ModuleNotEnabledError : public PermissionDeniedError {
public:
    using PermissionDeniedError::PermissionDeniedError;
};

class VenueSuspendedError : public PermissionDeniedError {
public:
    using PermissionDeniedError::PermissionDeniedError;
};

class NotYourReservationError : public PermissionDeniedError {
public:
    using PermissionDeniedError::PermissionDeniedError;
};

class NotFoundError : public ApiError {
public:
    using ApiError::ApiError;
};

class TableNotFoundError : public NotFoundError {
public:
    using NotFoundError::NotFoundError;
};

class ConflictError : public ApiError {
public:
    using ApiError::ApiError;
};

class TableTakenError : public ConflictError {
public:
    using ConflictError::ConflictError;
};

class CannotCancelError : public ConflictError {
public:
    using ConflictError::ConflictError;
};

class UnprocessableError : public ApiError {
public:
    using ApiError::ApiError;
};

class OutsideHoursError : public UnprocessableError {
public:
    using UnprocessableError::UnprocessableError;
};

class InThePastError : public UnprocessableError {
public:
    using UnprocessableError::UnprocessableError;
};

class TableTooSmallError : public UnprocessableError {
public:
    using UnprocessableError::UnprocessableError;
};

class RateLimitError : public ApiError {
public:
    using ApiError::ApiError;

    [[nodiscard]] std::optional<int> retry_after() const;
};

class ServerError : public ApiError {
public:
    using ApiError::ApiError;
};

class TemporarilyUnavailableError : public ServerError {
public:
    using ServerError::ServerError;
};

}
