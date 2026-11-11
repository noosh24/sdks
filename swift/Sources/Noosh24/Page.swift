import Foundation

public struct Page<Item: Sendable>: Sendable, RandomAccessCollection {
    public let items: [Item]
    public let total: Int
    public let limit: Int
    public let offset: Int

    public init(items: [Item], total: Int, limit: Int, offset: Int) {
        self.items = items
        self.total = total
        self.limit = limit
        self.offset = offset
    }

    public var hasMore: Bool {
        !items.isEmpty && offset + items.count < total
    }

    public var nextOffset: Int {
        offset + items.count
    }

    public var startIndex: Int { items.startIndex }
    public var endIndex: Int { items.endIndex }

    public subscript(position: Int) -> Item {
        items[position]
    }
}

extension Page: Equatable where Item: Equatable {}
extension Page: Hashable where Item: Hashable {}

public struct PagedSequence<Item: Sendable>: AsyncSequence, Sendable {
    public typealias Element = Item

    let start: Int
    let pageSize: Int
    let fetch: @Sendable (_ offset: Int, _ limit: Int) async throws -> Page<Item>

    public func makeAsyncIterator() -> Iterator {
        Iterator(sequence: self, offset: start)
    }

    public struct Iterator: AsyncIteratorProtocol {
        let sequence: PagedSequence
        var offset: Int
        var buffer: [Item] = []
        var position = 0
        var finished = false

        init(sequence: PagedSequence, offset: Int) {
            self.sequence = sequence
            self.offset = offset
        }

        public mutating func next() async throws -> Item? {
            while position >= buffer.count {
                if finished {
                    return nil
                }
                let page = try await sequence.fetch(offset, sequence.pageSize)
                buffer = page.items
                position = 0
                offset = page.nextOffset
                finished = !page.hasMore
            }
            defer { position += 1 }
            return buffer[position]
        }
    }
}

extension PagedSequence {
    public func collect() async throws -> [Item] {
        var items: [Item] = []
        for try await item in self {
            items.append(item)
        }
        return items
    }
}
