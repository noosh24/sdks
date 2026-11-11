import Foundation

public enum Noosh24Error: Error, Sendable, CustomStringConvertible, LocalizedError {
    case api(Noosh24APIError)
    case connection(message: String, underlying: (any Error)?)
    case timeout(message: String)
    case invalidArgument(String)

    public var message: String {
        switch self {
        case .api(let error): error.message
        case .connection(let message, _): message
        case .timeout(let message): message
        case .invalidArgument(let message): message
        }
    }

    public var apiError: Noosh24APIError? {
        if case .api(let error) = self { return error }
        return nil
    }

    public var code: Noosh24ErrorCode? {
        apiError?.code
    }

    public var kind: Noosh24APIError.Kind? {
        apiError?.kind
    }

    public var isConnectionError: Bool {
        switch self {
        case .connection, .timeout: true
        default: false
        }
    }

    public var isTimeout: Bool {
        if case .timeout = self { return true }
        return false
    }

    public var description: String {
        switch self {
        case .api(let error): error.description
        case .connection(let message, _): "Noosh24 connection error: \(message)"
        case .timeout(let message): "Noosh24 timeout: \(message)"
        case .invalidArgument(let message): "Noosh24 invalid argument: \(message)"
        }
    }

    public var errorDescription: String? {
        message
    }
}

public enum Noosh24ErrorCode: Hashable, Sendable, RawRepresentable, CaseIterable {
    case validationError
    case noApiKey
    case invalidApiKey
    case insufficientScope
    case moduleNotEnabled
    case venueSuspended
    case notYourReservation
    case notFound
    case tableNotFound
    case tableTaken
    case cannotCancel
    case outsideHours
    case inThePast
    case tableTooSmall
    case rateLimitExceeded
    case temporarilyUnavailable
    case unknown(String)

    public static let allCases: [Noosh24ErrorCode] = [
        .validationError, .noApiKey, .invalidApiKey, .insufficientScope, .moduleNotEnabled, .venueSuspended,
        .notYourReservation, .notFound, .tableNotFound, .tableTaken, .cannotCancel, .outsideHours, .inThePast,
        .tableTooSmall, .rateLimitExceeded, .temporarilyUnavailable,
    ]

    public init(rawValue: String) {
        self = Self.allCases.first { $0.rawValue == rawValue } ?? .unknown(rawValue)
    }

    public var rawValue: String {
        switch self {
        case .validationError: "validation_error"
        case .noApiKey: "no_api_key"
        case .invalidApiKey: "invalid_api_key"
        case .insufficientScope: "insufficient_scope"
        case .moduleNotEnabled: "module_not_enabled"
        case .venueSuspended: "venue_suspended"
        case .notYourReservation: "not_your_reservation"
        case .notFound: "not_found"
        case .tableNotFound: "table_not_found"
        case .tableTaken: "table_taken"
        case .cannotCancel: "cannot_cancel"
        case .outsideHours: "outside_hours"
        case .inThePast: "in_the_past"
        case .tableTooSmall: "table_too_small"
        case .rateLimitExceeded: "rate_limit_exceeded"
        case .temporarilyUnavailable: "temporarily_unavailable"
        case .unknown(let value): value
        }
    }

    public var kind: Noosh24APIError.Kind? {
        switch self {
        case .validationError: .validation
        case .noApiKey, .invalidApiKey: .authentication
        case .insufficientScope, .moduleNotEnabled, .venueSuspended, .notYourReservation: .permissionDenied
        case .notFound, .tableNotFound: .notFound
        case .tableTaken, .cannotCancel: .conflict
        case .outsideHours, .inThePast, .tableTooSmall: .unprocessable
        case .rateLimitExceeded: .rateLimit
        case .temporarilyUnavailable: .server
        case .unknown: nil
        }
    }
}

public struct Noosh24APIError: Error, Sendable, Hashable, CustomStringConvertible, LocalizedError {
    public enum Kind: String, Hashable, Sendable, CaseIterable {
        case validation
        case authentication
        case permissionDenied
        case notFound
        case conflict
        case unprocessable
        case rateLimit
        case server
        case other

        public init(status: Int) {
            switch status {
            case 400: self = .validation
            case 401: self = .authentication
            case 403: self = .permissionDenied
            case 404: self = .notFound
            case 409: self = .conflict
            case 422: self = .unprocessable
            case 429: self = .rateLimit
            case 500...: self = .server
            default: self = .other
            }
        }
    }

    public let status: Int
    public let code: Noosh24ErrorCode?
    public let message: String
    public let headers: [String: String]
    public let body: String

    public init(status: Int, code: Noosh24ErrorCode?, message: String, headers: [String: String] = [:], body: String = "") {
        self.status = status
        self.code = code
        self.message = message
        self.headers = Dictionary(headers.map { ($0.key.lowercased(), $0.value) }, uniquingKeysWith: { _, last in last })
        self.body = body
    }

    public var kind: Kind {
        code?.kind ?? Kind(status: status)
    }

    public var retryAfter: Int? {
        guard let header = headers["retry-after"],
            let seconds = Double(header.trimmingCharacters(in: .whitespaces)), seconds.isFinite
        else { return nil }
        return max(0, Int(min(seconds, Double(Int32.max))))
    }

    public var description: String {
        "Noosh24APIError(status: \(status), code: \(code?.rawValue ?? "nil"), kind: \(kind.rawValue), message: \(message))"
    }

    public var errorDescription: String? {
        message
    }

    static func from(status: Int, headers: [String: String], body: Data) -> Noosh24APIError {
        let text = String(decoding: body, as: UTF8.self)
        var code: String?
        var message = ""
        if case .object(let object)? = try? JSONDecoder().decode(JSONValue.self, from: body) {
            code = object["error"]?.stringValue
            message = object["message"]?.stringValue ?? ""
        }
        if message.isEmpty {
            message = code ?? "HTTP \(status)"
        }
        return Noosh24APIError(status: status, code: code.map(Noosh24ErrorCode.init(rawValue:)), message: message, headers: headers, body: text)
    }
}
