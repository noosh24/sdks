# frozen_string_literal: true

module Noosh24
  class Error < StandardError; end

  class APIConnectionError < Error; end

  class APITimeoutError < APIConnectionError; end

  class APIError < Error
    attr_reader :status, :code, :headers, :body

    def initialize(status, code, message, headers = {}, body = "")
      super(message)
      @status = status
      @code = code
      @headers = (headers || {}).to_h { |key, value| [key.to_s.downcase, value] }.freeze
      @body = body
    end

    def inspect
      "#<#{self.class.name} status=#{status} code=#{code.inspect} message=#{message.inspect}>"
    end

    def self.from_response(status, headers, body)
      parsed = parse(body)
      code = parsed["error"].is_a?(String) ? parsed["error"] : nil
      message = parsed["message"].is_a?(String) ? parsed["message"] : ""
      message = code || "HTTP #{status}" if message.empty?
      klass = BY_CODE[code] || BY_STATUS[status] || (status >= 500 ? ServerError : APIError)
      klass.new(status, code, message, headers, body)
    end

    def self.parse(body)
      parsed = JSON.parse(body.to_s)
      parsed.is_a?(Hash) ? parsed : {}
    rescue JSON::ParserError
      {}
    end
    private_class_method :parse
  end

  class ValidationError < APIError; end

  class AuthenticationError < APIError; end

  class NoApiKeyError < AuthenticationError; end

  class InvalidApiKeyError < AuthenticationError; end

  class PermissionDeniedError < APIError; end

  class InsufficientScopeError < PermissionDeniedError; end

  class ModuleNotEnabledError < PermissionDeniedError; end

  class VenueSuspendedError < PermissionDeniedError; end

  class NotYourReservationError < PermissionDeniedError; end

  class NotFoundError < APIError; end

  class TableNotFoundError < NotFoundError; end

  class ConflictError < APIError; end

  class TableTakenError < ConflictError; end

  class CannotCancelError < ConflictError; end

  class UnprocessableError < APIError; end

  class OutsideHoursError < UnprocessableError; end

  class InThePastError < UnprocessableError; end

  class TableTooSmallError < UnprocessableError; end

  class RateLimitError < APIError
    def retry_after
      value = headers["retry-after"]
      return nil if value.nil?

      [Float(value).to_i, 0].max
    rescue ArgumentError, TypeError, FloatDomainError
      nil
    end
  end

  class ServerError < APIError; end

  class TemporarilyUnavailableError < ServerError; end

  class APIError
    BY_CODE = {
      "validation_error" => ValidationError,
      "no_api_key" => NoApiKeyError,
      "invalid_api_key" => InvalidApiKeyError,
      "insufficient_scope" => InsufficientScopeError,
      "module_not_enabled" => ModuleNotEnabledError,
      "venue_suspended" => VenueSuspendedError,
      "not_your_reservation" => NotYourReservationError,
      "not_found" => NotFoundError,
      "table_not_found" => TableNotFoundError,
      "table_taken" => TableTakenError,
      "cannot_cancel" => CannotCancelError,
      "outside_hours" => OutsideHoursError,
      "in_the_past" => InThePastError,
      "table_too_small" => TableTooSmallError,
      "rate_limit_exceeded" => RateLimitError,
      "temporarily_unavailable" => TemporarilyUnavailableError
    }.freeze

    BY_STATUS = {
      400 => ValidationError,
      401 => AuthenticationError,
      403 => PermissionDeniedError,
      404 => NotFoundError,
      409 => ConflictError,
      422 => UnprocessableError,
      429 => RateLimitError
    }.freeze
  end
end
