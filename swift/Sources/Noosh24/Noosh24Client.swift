import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class Noosh24Client: Sendable {
    public static let version = "0.1.0"
    public static let defaultBaseURL = URL(string: "https://open-api.noosh24.com/v1")!

    public struct Configuration: Sendable {
        public var baseURL: URL
        public var timeout: Duration
        public var maxRetries: Int
        public var userAgent: String?

        public init(
            baseURL: URL = Noosh24Client.defaultBaseURL,
            timeout: Duration = .seconds(30),
            maxRetries: Int = 2,
            userAgent: String? = nil
        ) {
            self.baseURL = baseURL
            self.timeout = timeout
            self.maxRetries = maxRetries
            self.userAgent = userAgent
        }
    }

    public typealias Sleep = @Sendable (Duration) async throws -> Void

    public let menu: Menu
    public let reservations: Reservations
    public let orders: Orders
    public let payments: Payments
    public let tables: Tables
    public let customers: Customers
    public let loyalty: Loyalty
    public let stock: Stock
    public let reviews: Reviews

    let core: Core

    public init(
        apiKey: String,
        configuration: Configuration = Configuration(),
        transport: (any Noosh24Transport)? = nil,
        sleep: Sleep? = nil
    ) throws {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            throw Noosh24Error.invalidArgument("An API key is required")
        }
        var base = configuration.baseURL.absoluteString
        while base.hasSuffix("/") {
            base.removeLast()
        }
        let agent = "noosh24-swift/\(Self.version)"
        let custom = configuration.userAgent?.trimmingCharacters(in: .whitespaces) ?? ""
        core = Core(
            apiKey: key,
            baseURL: base,
            timeout: configuration.timeout,
            maxRetries: max(0, configuration.maxRetries),
            userAgent: custom.isEmpty ? agent : "\(custom) \(agent)",
            transport: transport ?? URLSessionTransport(),
            sleep: sleep ?? { try await Task.sleep(for: $0) }
        )
        menu = Menu(core: core)
        reservations = Reservations(core: core)
        orders = Orders(core: core)
        payments = Payments(core: core)
        tables = Tables(core: core)
        customers = Customers(core: core)
        loyalty = Loyalty(core: core)
        stock = Stock(core: core)
        reviews = Reviews(core: core)
    }

    public func whoami() async throws -> Whoami {
        try await core.one(Whoami.self, "/whoami")
    }
}

struct Core: Sendable {
    static let retryStatuses: Set<Int> = [429, 502, 503, 504]
    static let maxRetryWait = 60.0

    let apiKey: String
    let baseURL: String
    let timeout: Duration
    let maxRetries: Int
    let userAgent: String
    let transport: any Noosh24Transport
    let sleep: Noosh24Client.Sleep

    func send(
        _ method: String,
        _ path: String,
        query: [(String, String)] = [],
        body: Data? = nil,
        retryable: Bool = true
    ) async throws -> Noosh24HTTPResponse {
        var text = baseURL + path
        if !query.isEmpty {
            text += "?" + query.map { percentEncode($0.0) + "=" + percentEncode($0.1) }.joined(separator: "&")
        }
        guard let url = URL(string: text) else {
            throw Noosh24Error.invalidArgument("\(text) is not a valid URL")
        }
        var headers = [
            "Authorization": "Bearer " + apiKey,
            "Accept": "application/json",
            "User-Agent": userAgent,
        ]
        if body != nil {
            headers["Content-Type"] = "application/json"
        }
        let request = Noosh24HTTPRequest(method: method, url: url, headers: headers, body: body, timeout: timeout)

        var attempt = 0
        while true {
            let response: Noosh24HTTPResponse
            do {
                response = try await transport.send(request)
            } catch {
                let failure = try transportFailure(error)
                if retryable && attempt < maxRetries {
                    try await sleep(backoff(attempt))
                    attempt += 1
                    continue
                }
                throw failure
            }
            let headers = Dictionary(
                response.headers.map { ($0.key.lowercased(), $0.value) },
                uniquingKeysWith: { _, last in last }
            )
            if (200..<300).contains(response.status) {
                return Noosh24HTTPResponse(status: response.status, headers: headers, body: response.body)
            }
            if retryable, attempt < maxRetries, let wait = retryWait(response.status, headers, attempt) {
                try await sleep(wait)
                attempt += 1
                continue
            }
            throw Noosh24Error.api(Noosh24APIError.from(status: response.status, headers: headers, body: response.body))
        }
    }

    func data<T: Decodable>(_ type: T.Type, _ response: Noosh24HTTPResponse) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .noosh24
        if !response.body.isEmpty {
            let text = String(decoding: response.body, as: UTF8.self)
            guard let parsed = try? decoder.decode(JSONValue.self, from: response.body) else {
                throw Noosh24Error.api(
                    Noosh24APIError(
                        status: response.status, code: nil, message: "The API answered with a body that is not JSON",
                        headers: response.headers, body: text))
            }
            guard parsed["data"] != nil else {
                throw Noosh24Error.api(
                    Noosh24APIError(
                        status: response.status, code: nil, message: "The API answered without a \"data\" field",
                        headers: response.headers, body: text))
            }
            if let envelope = try? decoder.decode(Envelope<T>.self, from: response.body), let value = envelope.data {
                return value
            }
        }
        return try decoder.decode(T.self, from: Data("{}".utf8))
    }

    func one<T: Decodable>(_ type: T.Type, _ path: String, query: [(String, String)] = []) async throws -> T {
        try data(T.self, try await send("GET", path, query: query))
    }

    func all<T: Decodable & Sendable>(_ type: T.Type, _ path: String) async throws -> [T] {
        try await one(ListBody<T>.self, path).items ?? []
    }

    func page<T: Decodable & Sendable>(_ type: T.Type, _ path: String, _ options: ListOptions) async throws -> Page<T> {
        let body = try await one(ListBody<T>.self, path, query: options.query)
        let items = body.items ?? []
        return Page(
            items: items,
            total: body.total ?? items.count,
            limit: body.limit ?? options.limit ?? items.count,
            offset: body.offset ?? options.offset ?? 0
        )
    }

    func paginate<T: Decodable & Sendable>(
        _ type: T.Type,
        _ path: String,
        _ options: ListOptions,
        pageSize: Int
    ) -> PagedSequence<T> {
        PagedSequence(start: options.offset ?? 0, pageSize: options.limit ?? pageSize) { offset, limit in
            var next = options
            next.offset = offset
            next.limit = limit
            return try await page(T.self, path, next)
        }
    }

    private func transportFailure(_ error: any Error) throws -> Noosh24Error {
        if error is CancellationError || Task.isCancelled {
            throw CancellationError()
        }
        if let error = error as? Noosh24Error {
            switch error {
            case .connection, .timeout: return error
            default: throw error
            }
        }
        if let error = error as? URLError, error.code == .timedOut {
            return .timeout(message: "Request timed out after \(seconds(timeout)) s")
        }
        let reason = (error as? URLError)?.localizedDescription ?? String(describing: error)
        return .connection(message: "Could not reach the Noosh24 API: \(reason)", underlying: error)
    }

    private func retryWait(_ status: Int, _ headers: [String: String], _ attempt: Int) -> Duration? {
        guard Self.retryStatuses.contains(status) else { return nil }
        guard let header = headers["retry-after"] else { return backoff(attempt) }
        guard let value = Double(header.trimmingCharacters(in: .whitespaces)), !value.isNaN else {
            return backoff(attempt)
        }
        let wait = max(0, value)
        return wait <= Self.maxRetryWait ? .seconds(wait) : nil
    }

    private func backoff(_ attempt: Int) -> Duration {
        .seconds(min(8.0, 0.5 * pow(2.0, Double(attempt))))
    }

    private func seconds(_ duration: Duration) -> String {
        let parts = duration.components
        if parts.attoseconds == 0 {
            return String(parts.seconds)
        }
        return String(Double(parts.seconds) + Double(parts.attoseconds) / 1e18)
    }
}

struct Envelope<T: Decodable>: Decodable {
    let data: T?
}

struct ListBody<T: Decodable>: Decodable {
    let items: [T]?
    let total: Int?
    let limit: Int?
    let offset: Int?

    enum CodingKeys: String, CodingKey {
        case items, total, limit, offset
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = c.lenientList(T.self, forKey: .items)
        total = c.lenient(Int.self, forKey: .total)
        limit = c.lenient(Int.self, forKey: .limit)
        offset = c.lenient(Int.self, forKey: .offset)
    }
}

func percentEncode(_ text: String) -> String {
    var out = ""
    for byte in text.utf8 {
        switch byte {
        case 0x41...0x5A, 0x61...0x7A, 0x30...0x39, 0x2D, 0x2E, 0x5F, 0x7E:
            out.unicodeScalars.append(Unicode.Scalar(byte))
        default:
            out += "%" + String(byte, radix: 16, uppercase: true).leftPadded(to: 2)
        }
    }
    return out
}

extension String {
    fileprivate func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: "0", count: width - count) + self
    }
}
