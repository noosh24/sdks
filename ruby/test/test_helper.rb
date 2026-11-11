# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "noosh24"
require "minitest/autorun"

class MockTransport
  attr_reader :requests

  def initialize
    @queue = []
    @requests = []
  end

  def json(status, body, headers = {})
    @queue << Noosh24::Response.new(status: status, headers: headers, body: JSON.generate(body))
    self
  end

  def raw(status, text)
    @queue << Noosh24::Response.new(status: status, headers: {}, body: text)
    self
  end

  def fail_with(error)
    @queue << error
    self
  end

  def call(request)
    @requests << request
    raise "No response queued for #{request.http_method} #{request.url}" if @queue.empty?

    nxt = @queue.shift
    raise nxt if nxt.is_a?(Exception)

    nxt
  end

  def last
    @requests.last
  end
end

module ClientTest
  def setup
    @http = MockTransport.new
    @sleeps = []
  end

  def make_client(**)
    Noosh24::Client.new("nsk_test_123", transport: @http, sleep: ->(seconds) { @sleeps << seconds }, **)
  end

  def client
    @client ||= make_client
  end

  def query(request)
    text = URI(request.url).query.to_s
    text.split("&").each_with_object({}) do |pair, out|
      name, value = pair.split("=", 2).map { |part| URI.decode_uri_component(part) }
      (out[name] ||= []) << value
    end
  end

  def path(request)
    URI(request.url).path
  end

  def body(request)
    JSON.parse(request.body)
  end

  def page(items, total, limit = 20, offset = 0)
    { data: { items: items, total: total, limit: limit, offset: offset } }
  end
end
