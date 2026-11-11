import Foundation
import Noosh24

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct Boom: Error, CustomStringConvertible {
    let description: String
}

actor MockHTTP: Noosh24Transport {
    enum Reply {
        case response(Noosh24HTTPResponse)
        case failure(any Error)
    }

    private var queue: [Reply] = []
    private(set) var requests: [Noosh24HTTPRequest] = []

    func json(_ status: Int, _ body: JSONValue, headers: [String: String] = [:]) {
        let data = try! JSONEncoder().encode(body)
        queue.append(.response(Noosh24HTTPResponse(status: status, headers: headers.merging(["Content-Type": "application/json"]) { a, _ in a }, body: data)))
    }

    func raw(_ status: Int, _ text: String) {
        queue.append(.response(Noosh24HTTPResponse(status: status, headers: ["Content-Type": "text/html"], body: Data(text.utf8))))
    }

    func fail(_ error: any Error) {
        queue.append(.failure(error))
    }

    var last: Noosh24HTTPRequest {
        requests[requests.count - 1]
    }

    func send(_ request: Noosh24HTTPRequest) async throws -> Noosh24HTTPResponse {
        requests.append(request)
        guard !queue.isEmpty else {
            throw Boom(description: "No response queued for \(request.method) \(request.url)")
        }
        switch queue.removeFirst() {
        case .response(let response): return response
        case .failure(let error): throw error
        }
    }
}

actor Sleeps {
    private(set) var calls: [Duration] = []

    func record(_ duration: Duration) {
        calls.append(duration)
    }
}

struct Harness {
    let client: Noosh24Client
    let http: MockHTTP
    let sleeps: Sleeps

    init(maxRetries: Int = 2, baseURL: URL = Noosh24Client.defaultBaseURL, userAgent: String? = nil) throws {
        let http = MockHTTP()
        let sleeps = Sleeps()
        self.http = http
        self.sleeps = sleeps
        client = try Noosh24Client(
            apiKey: "nsk_test_123",
            configuration: .init(baseURL: baseURL, timeout: .seconds(30), maxRetries: maxRetries, userAgent: userAgent),
            transport: http,
            sleep: { await sleeps.record($0) }
        )
    }
}

func query(_ request: Noosh24HTTPRequest) -> [String: [String]] {
    var out: [String: [String]] = [:]
    guard let text = URLComponents(url: request.url, resolvingAgainstBaseURL: false)?.percentEncodedQuery else {
        return out
    }
    for pair in text.split(separator: "&") {
        let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let name = String(parts[0]).removingPercentEncoding ?? ""
        let value = parts.count > 1 ? (String(parts[1]).removingPercentEncoding ?? "") : ""
        out[name, default: []].append(value)
    }
    return out
}

func path(_ request: Noosh24HTTPRequest) -> String {
    URLComponents(url: request.url, resolvingAgainstBaseURL: false)?.percentEncodedPath ?? ""
}

func body(_ request: Noosh24HTTPRequest) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: request.body ?? Data())
}

func page(_ items: [JSONValue], _ total: Int, _ limit: Int = 20, _ offset: Int = 0) -> JSONValue {
    ["data": ["items": .array(items), "total": .number(Double(total)), "limit": .number(Double(limit)), "offset": .number(Double(offset))]]
}

func apiError(_ error: any Error) -> Noosh24APIError? {
    (error as? Noosh24Error)?.apiError
}

func utc(_ seconds: Int, _ fraction: Double = 0) -> Date {
    Date(timeIntervalSince1970: TimeInterval(seconds) + fraction)
}

func failure<T>(_ body: () async throws -> T) async -> (any Error)? {
    do {
        _ = try await body()
        return nil
    } catch {
        return error
    }
}
