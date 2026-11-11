# frozen_string_literal: true

module Noosh24
  Request = Data.define(:http_method, :url, :headers, :body, :timeout)
  Response = Data.define(:status, :headers, :body)

  class NetHTTPTransport
    def call(request)
      uri = URI(request.url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = request.timeout
      http.read_timeout = request.timeout
      http.write_timeout = request.timeout
      response = http.start { |conn| conn.request(build(uri, request)) }
      Response.new(status: response.code.to_i, headers: response.each_header.to_h, body: response.body.to_s)
    end

    private

    def build(uri, request)
      klass = request.http_method == "POST" ? Net::HTTP::Post : Net::HTTP::Get
      message = klass.new(uri.request_uri)
      request.headers.each { |name, value| message[name] = value }
      message.body = request.body if request.body
      message
    end
  end

  class Client
    DEFAULT_BASE_URL = "https://open-api.noosh24.com/v1"
    RETRY_STATUSES = [429, 502, 503, 504].freeze
    MAX_RETRY_WAIT = 60.0
    TIMEOUT_ERRORS = [Timeout::Error, Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout].freeze
    CONNECTION_ERRORS = [
      SocketError, SystemCallError, IOError, EOFError, OpenSSL::SSL::SSLError,
      Net::HTTPBadResponse, Net::ProtocolError
    ].freeze

    attr_reader :base_url, :timeout, :max_retries, :user_agent,
                :menu, :reservations, :orders, :payments, :tables, :customers, :loyalty, :stock, :reviews

    def initialize(api_key, base_url: nil, timeout: 30, max_retries: 2, user_agent: nil, transport: nil, sleep: nil)
      key = api_key.to_s.strip
      raise ArgumentError, "An API key is required" if key.empty?

      @api_key = key
      @base_url = (base_url || DEFAULT_BASE_URL).to_s.sub(%r{/+\z}, "")
      @timeout = timeout
      @max_retries = [Integer(max_retries), 0].max
      agent = "noosh24-ruby/#{VERSION}"
      @user_agent = user_agent.to_s.empty? ? agent : "#{user_agent} #{agent}"
      @transport = transport || NetHTTPTransport.new
      @sleep = sleep || ->(seconds) { Kernel.sleep(seconds) }

      @menu = Menu.new(self)
      @reservations = Reservations.new(self)
      @orders = Orders.new(self)
      @payments = Payments.new(self)
      @tables = Tables.new(self)
      @customers = Customers.new(self)
      @loyalty = Loyalty.new(self)
      @stock = Stock.new(self)
      @reviews = Reviews.new(self)
    end

    def whoami
      _, data = request("GET", "/whoami")
      Whoami.from_hash(data)
    end

    def inspect
      "#<#{self.class.name} base_url=#{base_url.inspect}>"
    end

    def request(http_method, path, query: nil, body: nil, retryable: true)
      req = Request.new(
        http_method: http_method,
        url: @base_url + path + self.class.query_string(query),
        headers: headers(body),
        body: body.nil? ? nil : JSON.generate(body),
        timeout: @timeout
      )
      attempt = 0
      loop do
        result, wait, error = perform(req, attempt)
        return result if error.nil?
        raise error unless retryable && attempt < @max_retries && !wait.nil?

        @sleep.call(wait)
        attempt += 1
      end
    end

    def self.query_string(query)
      pairs = []
      (query || {}).each do |name, value|
        Array(value).each do |item|
          next if item.nil?

          pairs << "#{escape(name.to_s)}=#{escape(item.to_s)}"
        end
      end
      pairs.empty? ? "" : "?#{pairs.join('&')}"
    end

    def self.escape(text)
      text.b.gsub(/[^A-Za-z0-9\-._~]/n) { |char| format("%%%02X", char.ord) }
    end

    private

    def headers(body)
      out = {
        "Authorization" => "Bearer #{@api_key}",
        "Accept" => "application/json",
        "User-Agent" => @user_agent
      }
      out["Content-Type"] = "application/json" unless body.nil?
      out
    end

    def perform(req, attempt)
      response = @transport.call(req)
      status = response.status.to_i
      headers = (response.headers || {}).to_h { |name, value| [name.to_s.downcase, Array(value).join(", ")] }
      return [[status, decode(status, headers, response.body.to_s)], nil, nil] if status.between?(200, 299)

      [nil, retry_wait(status, headers, attempt), APIError.from_response(status, headers, response.body.to_s)]
    rescue APIConnectionError => e
      [nil, backoff(attempt), e]
    rescue *TIMEOUT_ERRORS => e
      [nil, backoff(attempt), APITimeoutError.new("Request timed out after #{@timeout} s: #{e.message}")]
    rescue *CONNECTION_ERRORS => e
      [nil, backoff(attempt), APIConnectionError.new("Could not reach the Noosh24 API: #{e.message}")]
    end

    def decode(status, headers, body)
      return nil if body.empty?

      parsed = begin
        JSON.parse(body, freeze: true)
      rescue JSON::ParserError
        raise APIError.new(status, nil, "The API answered with a body that is not JSON", headers, body)
      end
      unless parsed.is_a?(Hash) && parsed.key?("data")
        raise APIError.new(status, nil, 'The API answered without a "data" field', headers, body)
      end

      parsed["data"]
    end

    def retry_wait(status, headers, attempt)
      return nil unless RETRY_STATUSES.include?(status)

      header = headers["retry-after"]
      return backoff(attempt) if header.nil?

      wait = Float(header, exception: false)
      return backoff(attempt) if wait.nil?

      wait = [wait, 0.0].max
      wait <= MAX_RETRY_WAIT ? wait : nil
    end

    def backoff(attempt)
      [8.0, 0.5 * (2**attempt)].min
    end
  end
end
