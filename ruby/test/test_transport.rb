# frozen_string_literal: true

require_relative "test_helper"
require "socket"

class TestTransport < Minitest::Test
  def setup
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @seen = Queue.new
  end

  def teardown
    @server.close
    @thread&.join(1)
  end

  def serve(response)
    @thread = Thread.new do
      conn = @server.accept
      head = +""
      head << conn.gets until head.end_with?("\r\n\r\n")
      length = head[/content-length: (\d+)/i, 1].to_i
      @seen << (head + conn.read(length).to_s)
      conn.write(response) unless response.nil?
      sleep 0.4 if response.nil?
      conn.close
    end
  end

  def test_real_transport_sends_the_request_and_reads_the_response
    body = '{"data":{"id":"res1","code":"K7Q2","status":"pending"}}'
    serve("HTTP/1.1 201 Created\r\nContent-Type: application/json\r\nX-Request-Id: r-1\r\n" \
          "Content-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
    client = Noosh24::Client.new("nsk_live", base_url: "http://127.0.0.1:#{@port}/v1", max_retries: 0)

    result = client.reservations.create(date: "2026-11-20", time: "19:30", guests: 2, guest_name: "Aysel",
                                        phone: "+994501234567")

    raw = @seen.pop

    assert_match(%r{\APOST /v1/reservations HTTP/1.1\r\n}, raw)
    assert_match(/^Authorization: Bearer nsk_live\r$/i, raw)
    assert_match(%r{^User-Agent: noosh24-ruby/#{Regexp.escape(Noosh24::VERSION)}\r$}i, raw)
    assert_match(%r{^Content-Type: application/json\r$}i, raw)
    assert raw.end_with?('"phone":"+994501234567"}')
    assert_predicate result, :created?
    assert_equal "K7Q2", result.reservation.code
  end

  def test_real_transport_maps_errors_with_headers
    body = '{"error":"not_found","message":"Yoxdur"}'
    serve("HTTP/1.1 404 Not Found\r\nX-Request-Id: r-2\r\nContent-Length: #{body.bytesize}\r\n" \
          "Connection: close\r\n\r\n#{body}")
    client = Noosh24::Client.new("nsk_live", base_url: "http://127.0.0.1:#{@port}/v1", max_retries: 0)

    error = assert_raises(Noosh24::NotFoundError) { client.customers.get("c 1") }

    assert_match(%r{\AGET /v1/customers/c%201 HTTP/1.1\r\n}, @seen.pop)
    assert_equal "Yoxdur", error.message
    assert_equal "r-2", error.headers["x-request-id"]
  end

  def test_real_transport_times_out
    serve(nil)
    client = Noosh24::Client.new("nsk_live", base_url: "http://127.0.0.1:#{@port}/v1", timeout: 0.2, max_retries: 0)

    assert_raises(Noosh24::APITimeoutError) { client.whoami }
  end

  def test_real_transport_connection_refused
    port = @port
    @server.close
    @server = TCPServer.new("127.0.0.1", 0)
    client = Noosh24::Client.new("nsk_live", base_url: "http://127.0.0.1:#{port}/v1", max_retries: 0)

    assert_raises(Noosh24::APIConnectionError) { client.whoami }
  end
end
