import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Noosh24HTTPRequest: Sendable, Hashable {
    public var method: String
    public var url: URL
    public var headers: [String: String]
    public var body: Data?
    public var timeout: Duration

    public init(method: String, url: URL, headers: [String: String], body: Data?, timeout: Duration) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}

public struct Noosh24HTTPResponse: Sendable, Hashable {
    public var status: Int
    public var headers: [String: String]
    public var body: Data

    public init(status: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

public protocol Noosh24Transport: Sendable {
    func send(_ request: Noosh24HTTPRequest) async throws -> Noosh24HTTPResponse
}

public final class URLSessionTransport: Noosh24Transport {
    private let session: URLSession
    private let ownsSession: Bool

    public init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        session = URLSession(configuration: configuration, delegate: NoRedirects(), delegateQueue: nil)
        ownsSession = true
    }

    public init(session: URLSession) {
        self.session = session
        ownsSession = false
    }

    deinit {
        if ownsSession {
            session.finishTasksAndInvalidate()
        }
    }

    public func send(_ request: Noosh24HTTPRequest) async throws -> Noosh24HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        let parts = request.timeout.components
        urlRequest.timeoutInterval = Double(parts.seconds) + Double(parts.attoseconds) / 1e18
        for (name, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        var headers: [String: String] = [:]
        for (name, value) in http.allHeaderFields {
            if let name = name as? String {
                headers[name.lowercased()] = value as? String ?? String(describing: value)
            }
        }
        return Noosh24HTTPResponse(status: http.statusCode, headers: headers, body: data)
    }
}

private final class NoRedirects: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
