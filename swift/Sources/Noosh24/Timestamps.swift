import Foundation

enum RFC3339 {
    static func parse(_ input: String) -> Date? {
        var scanner = Scanner(Array(input.trimmingCharacters(in: .whitespaces).utf8))
        guard let year = scanner.digits(4), scanner.take(UInt8(ascii: "-")),
            let month = scanner.digits(2), scanner.take(UInt8(ascii: "-")),
            let day = scanner.digits(2),
            (1...12).contains(month), (1...daysIn(month: month, year: year)).contains(day)
        else { return nil }
        var seconds = daysFromCivil(year: year, month: month, day: day) * 86_400
        var nanos = 0
        if scanner.atEnd {
            return Date(timeIntervalSince1970: TimeInterval(seconds))
        }
        guard scanner.take(UInt8(ascii: "T")) || scanner.take(UInt8(ascii: "t")) || scanner.take(UInt8(ascii: " ")),
            let hour = scanner.digits(2), scanner.take(UInt8(ascii: ":")),
            let minute = scanner.digits(2),
            hour < 24, minute < 60
        else { return nil }
        var second = 0
        if scanner.take(UInt8(ascii: ":")) {
            guard let value = scanner.digits(2), value <= 60 else { return nil }
            second = value
            if scanner.take(UInt8(ascii: ".")) || scanner.take(UInt8(ascii: ",")) {
                var count = 0
                while let digit = scanner.digit() {
                    if count < 9 {
                        nanos = nanos * 10 + digit
                    }
                    count += 1
                }
                guard count > 0 else { return nil }
                for _ in 0..<max(0, 9 - count) {
                    nanos *= 10
                }
            }
        }
        seconds += hour * 3_600 + minute * 60 + second
        let utc = scanner.take(UInt8(ascii: "Z")) || scanner.take(UInt8(ascii: "z"))
        if !utc, let sign = scanner.sign() {
            guard let offsetHours = scanner.digits(2), offsetHours < 24 else { return nil }
            _ = scanner.take(UInt8(ascii: ":"))
            let offsetMinutes = scanner.digits(2) ?? 0
            guard offsetMinutes < 60 else { return nil }
            seconds -= sign * (offsetHours * 3_600 + offsetMinutes * 60)
        }
        guard scanner.atEnd else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(nanos) / 1_000_000_000)
    }

    static func format(_ date: Date, offsetSeconds: Int) -> String {
        let interval = date.timeIntervalSince1970
        var whole = Int(interval.rounded(.down))
        var micros = Int(((interval - Double(whole)) * 1_000_000).rounded())
        if micros >= 1_000_000 {
            whole += 1
            micros -= 1_000_000
        }
        let local = whole + offsetSeconds
        let days = Int((Double(local) / 86_400).rounded(.down))
        let secondOfDay = local - days * 86_400
        let (year, month, day) = civilFromDays(days)
        var text = pad(year, 4) + "-" + pad(month, 2) + "-" + pad(day, 2) + "T"
        text += pad(secondOfDay / 3_600, 2) + ":" + pad(secondOfDay % 3_600 / 60, 2) + ":" + pad(secondOfDay % 60, 2)
        if micros != 0 {
            text += "." + pad(micros, 6)
        }
        let sign = offsetSeconds < 0 ? "-" : "+"
        let minutes = abs(offsetSeconds) / 60
        return text + sign + pad(minutes / 60, 2) + ":" + pad(minutes % 60, 2)
    }

    static func daysIn(month: Int, year: Int) -> Int {
        switch month {
        case 2: (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }

    static func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    static func civilFromDays(_ days: Int) -> (Int, Int, Int) {
        let z = days + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let day = doy - (153 * mp + 2) / 5 + 1
        let month = mp < 10 ? mp + 3 : mp - 9
        return (yoe + era * 400 + (month <= 2 ? 1 : 0), month, day)
    }

    static func pad(_ value: Int, _ width: Int) -> String {
        let text = String(value)
        return text.count >= width ? text : String(repeating: "0", count: width - text.count) + text
    }

    private struct Scanner {
        let bytes: [UInt8]
        var index = 0

        init(_ bytes: [UInt8]) {
            self.bytes = bytes
        }

        var atEnd: Bool { index == bytes.count }

        mutating func take(_ byte: UInt8) -> Bool {
            guard index < bytes.count, bytes[index] == byte else { return false }
            index += 1
            return true
        }

        mutating func digit() -> Int? {
            guard index < bytes.count, (48...57).contains(bytes[index]) else { return nil }
            index += 1
            return Int(bytes[index - 1] - 48)
        }

        mutating func digits(_ count: Int) -> Int? {
            var value = 0
            for _ in 0..<count {
                guard let digit = digit() else { return nil }
                value = value * 10 + digit
            }
            return value
        }

        mutating func sign() -> Int? {
            if take(UInt8(ascii: "+")) { return 1 }
            if take(UInt8(ascii: "-")) { return -1 }
            return nil
        }
    }
}

extension JSONDecoder.DateDecodingStrategy {
    public static var noosh24: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = RFC3339.parse(text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "\(text) is not an RFC 3339 timestamp")
            }
            return date
        }
    }
}

public struct PlainDate: Hashable, Sendable, Codable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let description: String

    public init(year: Int, month: Int, day: Int) {
        description = RFC3339.pad(year, 4) + "-" + RFC3339.pad(month, 2) + "-" + RFC3339.pad(day, 2)
    }

    public init(_ date: Date, in timeZone: TimeZone) {
        let local = Int(date.timeIntervalSince1970.rounded(.down)) + timeZone.secondsFromGMT(for: date)
        let (year, month, day) = RFC3339.civilFromDays(Int((Double(local) / 86_400).rounded(.down)))
        self.init(year: year, month: month, day: day)
    }

    public init?(parsing text: String) {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
            let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
            (1...12).contains(month), (1...RFC3339.daysIn(month: month, year: year)).contains(day)
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    public init(stringLiteral value: String) {
        description = value
    }

    public init(from decoder: any Decoder) throws {
        description = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

public struct ZonedDateTime: Hashable, Sendable, CustomStringConvertible {
    public let date: Date
    public let timeZone: TimeZone

    public init(_ date: Date, in timeZone: TimeZone) {
        self.date = date
        self.timeZone = timeZone
    }

    public var description: String {
        RFC3339.format(date, offsetSeconds: timeZone.secondsFromGMT(for: date))
    }
}
