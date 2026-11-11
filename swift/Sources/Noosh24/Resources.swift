import Foundation

public struct Sort: Hashable, Sendable, ExpressibleByStringLiteral, ExpressibleByArrayLiteral {
    public let fields: [String]

    public init(_ fields: [String]) {
        self.fields = fields.filter { !$0.isEmpty }
    }

    public init(_ fields: String...) {
        self.init(fields)
    }

    public init(stringLiteral value: String) {
        self.init([value])
    }

    public init(arrayLiteral elements: String...) {
        self.init(elements)
    }
}

public struct ProductExpand: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
    public static let modifierGroups = ProductExpand(rawValue: "modifierGroups")
    public static let translations = ProductExpand(rawValue: "translations")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        rawValue = value
    }
}

struct ListOptions: Sendable {
    var limit: Int?
    var offset: Int?
    var sort: Sort = []
    var filter: (any WhereExpression)?
    var expand: [ProductExpand] = []

    var query: [(String, String)] {
        var query: [(String, String)] = []
        if let limit {
            query.append(("limit", String(limit)))
        }
        if let offset {
            query.append(("offset", String(offset)))
        }
        for field in sort.fields {
            query.append(("sort", field))
        }
        if let clause = filter?.whereClause, !clause.isEmpty {
            query.append(("where", clause))
        }
        for item in expand where !item.rawValue.isEmpty {
            query.append(("expand", item.rawValue))
        }
        return query
    }
}

func pathID(_ id: String) throws -> String {
    guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw Noosh24Error.invalidArgument("An id is required")
    }
    return percentEncode(id)
}

extension Noosh24Client {
    public struct Menu: Sendable {
        let core: Core

        public func listCategories() async throws -> [Category] {
            try await core.all(Category.self, "/menu/categories")
        }

        public func listProducts(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil,
            expand: [ProductExpand] = []
        ) async throws -> Page<Product> {
            try await core.page(Product.self, "/menu/products", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter, expand: expand))
        }

        public func iterateProducts(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil,
            expand: [ProductExpand] = []
        ) -> PagedSequence<Product> {
            let options = ListOptions(limit: limit, offset: offset, sort: sort, filter: filter, expand: expand)
            return core.paginate(Product.self, "/menu/products", options, pageSize: options.expand.isEmpty ? 100 : 50)
        }

        public func getProduct(_ id: String, expand: [ProductExpand] = []) async throws -> Product {
            try await core.one(Product.self, "/menu/products/" + pathID(id), query: ListOptions(expand: expand).query)
        }

        public func getStopList() async throws -> [StopListItem] {
            try await core.all(StopListItem.self, "/menu/stop-list")
        }
    }

    public struct Reservations: Sendable {
        let core: Core

        public func list(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) async throws -> Page<Reservation> {
            try await core.page(Reservation.self, "/reservations", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter))
        }

        public func iterate(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) -> PagedSequence<Reservation> {
            core.paginate(Reservation.self, "/reservations", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter), pageSize: 100)
        }

        public func get(_ id: String) async throws -> Reservation {
            try await core.one(Reservation.self, "/reservations/" + pathID(id))
        }

        public func availability(date: PlainDate, time: String, guests: Int? = nil) async throws -> TableAvailability {
            var query = [("date", date.description), ("time", time)]
            if let guests {
                query.append(("guests", String(guests)))
            }
            return try await core.one(TableAvailability.self, "/reservations/availability", query: query)
        }

        public func create(_ reservation: NewReservation) async throws -> CreateReservationResult {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            let body = try encoder.encode(reservation)
            let idempotent = !(reservation.externalRef ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let response = try await core.send("POST", "/reservations", body: body, retryable: idempotent)
            return CreateReservationResult(reservation: try core.data(Reservation.self, response), created: response.status == 201)
        }

        public func cancel(_ id: String) async throws -> Reservation {
            let response = try await core.send("POST", "/reservations/\(try pathID(id))/cancel")
            return try core.data(Reservation.self, response)
        }
    }

    public struct Orders: Sendable {
        let core: Core

        public func list(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) async throws -> Page<Order> {
            try await core.page(Order.self, "/orders", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter))
        }

        public func iterate(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) -> PagedSequence<Order> {
            core.paginate(Order.self, "/orders", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter), pageSize: 100)
        }

        public func get(_ id: String) async throws -> Order {
            try await core.one(Order.self, "/orders/" + pathID(id))
        }

        public func listBills(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) async throws -> Page<Bill> {
            try await core.page(Bill.self, "/bills", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter))
        }

        public func iterateBills(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) -> PagedSequence<Bill> {
            core.paginate(Bill.self, "/bills", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter), pageSize: 50)
        }

        public func getBill(_ id: String) async throws -> Bill {
            try await core.one(Bill.self, "/bills/" + pathID(id))
        }
    }

    public struct Payments: Sendable {
        let core: Core

        public func list(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) async throws -> Page<Payment> {
            try await core.page(Payment.self, "/payments", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter))
        }

        public func iterate(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) -> PagedSequence<Payment> {
            core.paginate(Payment.self, "/payments", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter), pageSize: 100)
        }

        public func get(_ id: String) async throws -> Payment {
            try await core.one(Payment.self, "/payments/" + pathID(id))
        }

        public func zReport(date: PlainDate? = nil) async throws -> ZReport {
            try await core.one(ZReport.self, "/reports/z", query: date.map { [("date", $0.description)] } ?? [])
        }
    }

    public struct Tables: Sendable {
        let core: Core

        public func list() async throws -> [Table] {
            try await core.all(Table.self, "/tables")
        }

        public func listHalls() async throws -> [Hall] {
            try await core.all(Hall.self, "/halls")
        }
    }

    public struct Customers: Sendable {
        let core: Core

        public func list(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) async throws -> Page<Customer> {
            try await core.page(Customer.self, "/customers", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter))
        }

        public func iterate(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) -> PagedSequence<Customer> {
            core.paginate(Customer.self, "/customers", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter), pageSize: 100)
        }

        public func get(_ id: String) async throws -> Customer {
            try await core.one(Customer.self, "/customers/" + pathID(id))
        }
    }

    public struct Loyalty: Sendable {
        let core: Core

        public func getProgram() async throws -> LoyaltyProgram {
            try await core.one(LoyaltyProgram.self, "/loyalty/program")
        }

        public func listCards(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) async throws -> Page<LoyaltyCard> {
            try await core.page(LoyaltyCard.self, "/loyalty/cards", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter))
        }

        public func iterateCards(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) -> PagedSequence<LoyaltyCard> {
            core.paginate(LoyaltyCard.self, "/loyalty/cards", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter), pageSize: 100)
        }
    }

    public struct Stock: Sendable {
        let core: Core

        public func listIngredients(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) async throws -> Page<Ingredient> {
            try await core.page(Ingredient.self, "/stock/ingredients", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter))
        }

        public func iterateIngredients(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) -> PagedSequence<Ingredient> {
            core.paginate(Ingredient.self, "/stock/ingredients", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter), pageSize: 100)
        }

        public func listMoves(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) async throws -> Page<StockMove> {
            try await core.page(StockMove.self, "/stock/moves", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter))
        }

        public func iterateMoves(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) -> PagedSequence<StockMove> {
            core.paginate(StockMove.self, "/stock/moves", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter), pageSize: 100)
        }

        public func listStores() async throws -> [StockStore] {
            try await core.all(StockStore.self, "/stock/stores")
        }
    }

    public struct Reviews: Sendable {
        let core: Core

        public func list(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) async throws -> Page<Review> {
            try await core.page(Review.self, "/reviews", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter))
        }

        public func iterate(
            limit: Int? = nil, offset: Int? = nil, sort: Sort = [], where filter: (any WhereExpression)? = nil
        ) -> PagedSequence<Review> {
            core.paginate(Review.self, "/reviews", ListOptions(limit: limit, offset: offset, sort: sort, filter: filter), pageSize: 100)
        }
    }
}
