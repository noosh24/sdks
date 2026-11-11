# frozen_string_literal: true

require_relative "test_helper"

class TestClient < Minitest::Test
  include ClientTest

  def test_sends_key_and_headers_to_default_base_url
    @http.json(200, {
                 data: {
                   restaurant: { id: "r1", name: "Masago", slug: "masago" },
                   key: { id: "k1", name: "Wolt", prefix: "nsk_Ab3dE9xQ", scopes: ["menu:read", "orders:read"] },
                   subscription: { status: "active", modules: ["loyalty"] },
                   features: { loyalty: true, inventory: false }
                 }
               })

    me = client.whoami

    request = @http.last

    assert_equal "GET", request.http_method
    assert_equal "https://open-api.noosh24.com/v1/whoami", request.url
    assert_equal "Bearer nsk_test_123", request.headers["Authorization"]
    assert_equal "application/json", request.headers["Accept"]
    assert_equal "noosh24-ruby/#{Noosh24::VERSION}", request.headers["User-Agent"]
    assert_nil request.body
    refute request.headers.key?("Content-Type")
    assert_equal 30, request.timeout
    assert_equal "Masago", me.restaurant.name
    assert_equal ["menu:read", "orders:read"], me.key.scopes
    assert_equal "active", me.subscription.status
    assert me.features.loyalty
    refute me.features.inventory
    assert_predicate me, :frozen?
  end

  def test_custom_base_url_user_agent_and_timeout
    custom = make_client(base_url: "http://localhost:8080/v1/", user_agent: "acme-pos/2.1", timeout: 5)
    @http.json(200, { data: {} })

    custom.whoami

    assert_equal "http://localhost:8080/v1/whoami", @http.last.url
    assert_equal "acme-pos/2.1 noosh24-ruby/#{Noosh24::VERSION}", @http.last.headers["User-Agent"]
    assert_equal 5, @http.last.timeout
  end

  def test_rejects_empty_key
    assert_raises(ArgumentError) { Noosh24::Client.new("  ") }
    assert_raises(ArgumentError) { Noosh24::Client.new(nil) }
  end

  def test_retries_rate_limit_after_retry_after
    @http.json(429, { error: "rate_limit_exceeded", message: "slow down" }, { "Retry-After" => "3" })
    @http.json(200, { data: { items: [], total: 0 } })

    assert_equal [], client.tables.list
    assert_equal 2, @http.requests.size
    assert_equal [3.0], @sleeps
  end

  def test_gives_up_after_max_retries
    custom = make_client(max_retries: 1)
    @http.json(429, { error: "rate_limit_exceeded", message: "slow down" }, { "Retry-After" => "1" })
    @http.json(429, { error: "rate_limit_exceeded", message: "slow down" }, { "Retry-After" => "7" })

    error = assert_raises(Noosh24::RateLimitError) { custom.tables.list }

    assert_equal 429, error.status
    assert_equal "rate_limit_exceeded", error.code
    assert_equal 7, error.retry_after
    assert_equal "slow down", error.message
    assert_equal "7", error.headers["retry-after"]
    assert_equal 2, @http.requests.size
  end

  def test_retry_after_is_nil_when_absent
    custom = make_client(max_retries: 0)
    @http.json(429, { error: "rate_limit_exceeded" })

    error = assert_raises(Noosh24::RateLimitError) { custom.tables.list }

    assert_nil error.retry_after
  end

  def test_does_not_wait_longer_than_a_minute
    @http.json(429, { error: "rate_limit_exceeded" }, { "Retry-After" => "120" })

    assert_raises(Noosh24::RateLimitError) { client.tables.list }
    assert_equal 1, @http.requests.size
    assert_empty @sleeps
  end

  def test_backs_off_on_temporarily_unavailable
    3.times { @http.json(503, { error: "temporarily_unavailable", message: "try again" }) }

    assert_raises(Noosh24::TemporarilyUnavailableError) { client.tables.list_halls }
    assert_equal 3, @http.requests.size
    assert_equal [0.5, 1.0], @sleeps
  end

  def test_retries_connection_errors_on_reads
    custom = make_client(max_retries: 1)
    @http.fail_with(Errno::ECONNRESET.new("connection reset"))
    @http.json(200, { data: { items: [{ id: "h1", name: "Main", position: 1 }], total: 1 } })

    assert_equal "Main", custom.tables.list_halls.first.name

    @http.fail_with(Errno::ECONNRESET.new("connection reset")).fail_with(SocketError.new("connection reset"))
    error = assert_raises(Noosh24::APIConnectionError) { custom.tables.list_halls }
    assert_match(/connection reset/, error.message)
    assert_equal [0.5, 0.5], @sleeps
  end

  def test_timeout
    custom = make_client(max_retries: 0)
    @http.fail_with(Net::ReadTimeout.new)

    error = assert_raises(Noosh24::APITimeoutError) { custom.whoami }
    assert_kind_of Noosh24::APIConnectionError, error
  end

  def test_body_that_is_not_json_is_an_api_error
    @http.raw(200, "<html>gateway</html>")

    error = assert_raises(Noosh24::APIError) { client.whoami }
    assert_equal 200, error.status
  end

  def test_body_without_data_is_an_api_error
    @http.json(200, { items: [] })

    assert_raises(Noosh24::APIError) { client.whoami }
  end

  def test_builds_repeated_query_parameters
    text = Noosh24::Client.query_string(
      { "sort" => ["price desc", "name asc"], "where" => "a = 1", "skip" => nil, "available" => true }
    )

    assert_equal "?sort=price%20desc&sort=name%20asc&where=a%20%3D%201&available=true", text
    assert_equal "", Noosh24::Client.query_string(nil)
  end
end
