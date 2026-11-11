import Foundation

public protocol Noosh24Model: Codable, Sendable, Hashable {
    var raw: JSONValue? { get }
}

struct Lossy<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: any Decoder) throws {
        value = try? decoder.singleValueContainer().decode(Value.self)
    }
}

extension KeyedDecodingContainer {
    func lenient<T: Decodable>(_ type: T.Type, forKey key: Key) -> T? {
        guard let value = try? decodeIfPresent(T.self, forKey: key) else { return nil }
        return value
    }

    func lenientDate(forKey key: Key) -> Date? {
        if let date = try? decodeIfPresent(Date.self, forKey: key) {
            return date
        }
        guard let text = try? decodeIfPresent(String.self, forKey: key) else { return nil }
        return RFC3339.parse(text)
    }

    func lenientList<T: Decodable>(_ type: T.Type, forKey key: Key) -> [T]? {
        guard let items = try? decodeIfPresent([Lossy<T>].self, forKey: key) else { return nil }
        return items.compactMap(\.value)
    }

    func lenientMap<T: Decodable>(_ type: T.Type, forKey key: Key) -> [String: T]? {
        guard let items = try? decodeIfPresent([String: Lossy<T>].self, forKey: key) else { return nil }
        return items.compactMapValues(\.value)
    }
}
