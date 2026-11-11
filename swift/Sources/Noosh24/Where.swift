import Foundation

public protocol WhereExpression: Sendable {
    var whereClause: String { get }
}

extension String: WhereExpression {
    public var whereClause: String { self }
}

public protocol WhereValue: Sendable {
    func whereLiteral() throws -> String
}

extension String: WhereValue {
    public func whereLiteral() throws -> String {
        "'" + replacingOccurrences(of: "'", with: "''") + "'"
    }
}

extension Bool: WhereValue {
    public func whereLiteral() throws -> String {
        self ? "true" : "false"
    }
}

extension Int: WhereValue {
    public func whereLiteral() throws -> String { String(self) }
}

extension Int32: WhereValue {
    public func whereLiteral() throws -> String { String(self) }
}

extension Int64: WhereValue {
    public func whereLiteral() throws -> String { String(self) }
}

extension UInt: WhereValue {
    public func whereLiteral() throws -> String { String(self) }
}

extension Double: WhereValue {
    public func whereLiteral() throws -> String {
        guard isFinite else {
            throw Noosh24Error.invalidArgument("Numbers in where must be finite")
        }
        if rounded(.towardZero) == self, abs(self) < 9.2e18 {
            return String(Int64(self))
        }
        return String(self)
    }
}

extension Float: WhereValue {
    public func whereLiteral() throws -> String {
        guard isFinite else {
            throw Noosh24Error.invalidArgument("Numbers in where must be finite")
        }
        if rounded(.towardZero) == self, abs(self) < 9.2e18 {
            return String(Int64(self))
        }
        return String(self)
    }
}

extension Date: WhereValue {
    public func whereLiteral() throws -> String {
        guard timeIntervalSince1970.isFinite else {
            throw Noosh24Error.invalidArgument("where got an invalid Date")
        }
        return "'" + RFC3339.format(self, offsetSeconds: 0) + "'"
    }
}

extension ZonedDateTime: WhereValue {
    public func whereLiteral() throws -> String {
        "'" + description + "'"
    }
}

extension PlainDate: WhereValue {
    public func whereLiteral() throws -> String {
        "'" + description + "'"
    }
}

extension Optional: WhereValue where Wrapped: WhereValue {
    public func whereLiteral() throws -> String {
        guard let value = self else {
            throw Noosh24Error.invalidArgument("where takes strings, numbers, booleans and dates, not nil")
        }
        return try value.whereLiteral()
    }
}

public struct Where: Hashable, Sendable, CustomStringConvertible, WhereExpression {
    public let conditions: [String]

    public init() {
        conditions = []
    }

    private init(conditions: [String]) {
        self.conditions = conditions
    }

    public var description: String {
        conditions.joined(separator: " AND ")
    }

    public var whereClause: String {
        description
    }

    public func eq(_ field: String, _ value: some WhereValue) throws -> Where {
        try adding(field, "=", value)
    }

    public func ne(_ field: String, _ value: some WhereValue) throws -> Where {
        try adding(field, "!=", value)
    }

    public func gt(_ field: String, _ value: some WhereValue) throws -> Where {
        try adding(field, ">", value)
    }

    public func gte(_ field: String, _ value: some WhereValue) throws -> Where {
        try adding(field, ">=", value)
    }

    public func lt(_ field: String, _ value: some WhereValue) throws -> Where {
        try adding(field, "<", value)
    }

    public func lte(_ field: String, _ value: some WhereValue) throws -> Where {
        try adding(field, "<=", value)
    }

    public func `in`(_ field: String, _ values: [any WhereValue]) throws -> Where {
        guard !values.isEmpty else {
            throw Noosh24Error.invalidArgument("in() needs at least one value")
        }
        let literals = try values.map { try $0.whereLiteral() }
        return Where(conditions: conditions + ["\(try Self.checked(field)) in (\(literals.joined(separator: ", ")))"])
    }

    private func adding(_ field: String, _ op: String, _ value: some WhereValue) throws -> Where {
        Where(conditions: conditions + ["\(try Self.checked(field)) \(op) \(try value.whereLiteral())"])
    }

    private static func checked(_ field: String) throws -> String {
        let bytes = Array(field.utf8)
        guard let first = bytes.first, isLetter(first),
            bytes.dropFirst().allSatisfy({ isLetter($0) || (48...57).contains($0) || $0 == 95 || $0 == 46 })
        else {
            throw Noosh24Error.invalidArgument("\"\(field)\" is not a field name")
        }
        return field
    }

    private static func isLetter(_ byte: UInt8) -> Bool {
        (65...90).contains(byte) || (97...122).contains(byte)
    }
}
