# frozen_string_literal: true

require_relative "test_helper"

class TestErrors < Minitest::Test
  include ClientTest

  N = Noosh24

  CASES = [
    [400, "validation_error", N::ValidationError, N::APIError],
    [401, "no_api_key", N::NoApiKeyError, N::AuthenticationError],
    [401, "invalid_api_key", N::InvalidApiKeyError, N::AuthenticationError],
    [403, "insufficient_scope", N::InsufficientScopeError, N::PermissionDeniedError],
    [403, "module_not_enabled", N::ModuleNotEnabledError, N::PermissionDeniedError],
    [403, "venue_suspended", N::VenueSuspendedError, N::PermissionDeniedError],
    [403, "not_your_reservation", N::NotYourReservationError, N::PermissionDeniedError],
    [404, "not_found", N::NotFoundError, N::APIError],
    [404, "table_not_found", N::TableNotFoundError, N::NotFoundError],
    [409, "table_taken", N::TableTakenError, N::ConflictError],
    [409, "cannot_cancel", N::CannotCancelError, N::ConflictError],
    [422, "outside_hours", N::OutsideHoursError, N::UnprocessableError],
    [422, "in_the_past", N::InThePastError, N::UnprocessableError],
    [422, "table_too_small", N::TableTooSmallError, N::UnprocessableError],
    [429, "rate_limit_exceeded", N::RateLimitError, N::APIError],
    [503, "temporarily_unavailable", N::TemporarilyUnavailableError, N::ServerError],
    [403, "something_new", N::PermissionDeniedError, N::APIError],
    [409, "something_new", N::ConflictError, N::APIError],
    [500, "query_failed", N::ServerError, N::APIError],
    [418, nil, N::APIError, N::Error]
  ].freeze

  CASES.each do |status, code, klass, parent|
    define_method("test_maps_#{status}_#{code || 'no_code'}") do
      custom = make_client(max_retries: 0)
      @http.json(status, code.nil? ? { nope: true } : { error: code, message: "Mesaj" })

      error = assert_raises(N::APIError) { custom.customers.get("c1") }

      assert_instance_of klass, error
      assert_kind_of parent, error
      assert_kind_of N::Error, error
      assert_kind_of StandardError, error
      assert_equal status, error.status
      if code.nil?
        assert_nil error.code
      else
        assert_equal code, error.code
      end

      assert_equal(code.nil? ? "HTTP #{status}" : "Mesaj", error.message)
    end
  end

  def test_missing_message_falls_back_to_code
    error = N::APIError.from_response(409, { "X-Request-Id" => "abc" }, '{"error":"table_taken"}')

    assert_instance_of N::TableTakenError, error
    assert_equal "table_taken", error.message
    assert_equal "abc", error.headers["x-request-id"]
    assert_equal '{"error":"table_taken"}', error.body
  end

  def test_validation_error_is_not_retried
    @http.json(400, { error: "validation_error", message: '"nope" is not a filterable field on this resource' })

    error = assert_raises(N::ValidationError) { client.menu.list_products(where: "nope = 1") }
    assert_match(/not a filterable field/, error.message)
    assert_equal 1, @http.requests.size
  end
end
