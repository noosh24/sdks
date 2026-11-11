public enum ReservationStatus: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case pending
    case confirmed
    case arriving
    case checkedIn
    case completed
    case cancelled
    case noShow
    case unknown(String)

    public static let allCases: [ReservationStatus] = [.pending, .confirmed, .arriving, .checkedIn, .completed, .cancelled, .noShow]

    public init(rawValue: String) {
        switch rawValue {
        case "pending": self = .pending
        case "confirmed": self = .confirmed
        case "arriving": self = .arriving
        case "checked_in": self = .checkedIn
        case "completed": self = .completed
        case "cancelled": self = .cancelled
        case "no_show": self = .noShow
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .pending: "pending"
        case .confirmed: "confirmed"
        case .arriving: "arriving"
        case .checkedIn: "checked_in"
        case .completed: "completed"
        case .cancelled: "cancelled"
        case .noShow: "no_show"
        case .unknown(let value): value
        }
    }
}

public enum ReservationSource: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case noosh24
    case openApi
    case unknown(String)

    public static let allCases: [ReservationSource] = [.noosh24, .openApi]

    public init(rawValue: String) {
        switch rawValue {
        case "noosh24": self = .noosh24
        case "open_api": self = .openApi
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .noosh24: "noosh24"
        case .openApi: "open_api"
        case .unknown(let value): value
        }
    }
}

public enum OrderKind: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case table
    case counter
    case delivery
    case unknown(String)

    public static let allCases: [OrderKind] = [.table, .counter, .delivery]

    public init(rawValue: String) {
        switch rawValue {
        case "table": self = .table
        case "counter": self = .counter
        case "delivery": self = .delivery
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .table: "table"
        case .counter: "counter"
        case .delivery: "delivery"
        case .unknown(let value): value
        }
    }
}

public enum OrderStatus: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case pendingWaiter
    case new
    case accepted
    case preparing
    case ready
    case served
    case cancelled
    case unknown(String)

    public static let allCases: [OrderStatus] = [.pendingWaiter, .new, .accepted, .preparing, .ready, .served, .cancelled]

    public init(rawValue: String) {
        switch rawValue {
        case "pending_waiter": self = .pendingWaiter
        case "new": self = .new
        case "accepted": self = .accepted
        case "preparing": self = .preparing
        case "ready": self = .ready
        case "served": self = .served
        case "cancelled": self = .cancelled
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .pendingWaiter: "pending_waiter"
        case .new: "new"
        case .accepted: "accepted"
        case .preparing: "preparing"
        case .ready: "ready"
        case .served: "served"
        case .cancelled: "cancelled"
        case .unknown(let value): value
        }
    }
}

public enum OrderItemStatus: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case new
    case preparing
    case ready
    case cancelled
    case unknown(String)

    public static let allCases: [OrderItemStatus] = [.new, .preparing, .ready, .cancelled]

    public init(rawValue: String) {
        switch rawValue {
        case "new": self = .new
        case "preparing": self = .preparing
        case "ready": self = .ready
        case "cancelled": self = .cancelled
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .new: "new"
        case .preparing: "preparing"
        case .ready: "ready"
        case .cancelled: "cancelled"
        case .unknown(let value): value
        }
    }
}

public enum BillStatus: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case open
    case billRequested
    case paid
    case closed
    case abandoned
    case merged
    case unknown(String)

    public static let allCases: [BillStatus] = [.open, .billRequested, .paid, .closed, .abandoned, .merged]

    public init(rawValue: String) {
        switch rawValue {
        case "open": self = .open
        case "bill_requested": self = .billRequested
        case "paid": self = .paid
        case "closed": self = .closed
        case "abandoned": self = .abandoned
        case "merged": self = .merged
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .open: "open"
        case .billRequested: "bill_requested"
        case .paid: "paid"
        case .closed: "closed"
        case .abandoned: "abandoned"
        case .merged: "merged"
        case .unknown(let value): value
        }
    }
}

public enum PaymentStatus: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case pending
    case requiresAction
    case succeeded
    case failed
    case refunded
    case unknown(String)

    public static let allCases: [PaymentStatus] = [.pending, .requiresAction, .succeeded, .failed, .refunded]

    public init(rawValue: String) {
        switch rawValue {
        case "pending": self = .pending
        case "requires_action": self = .requiresAction
        case "succeeded": self = .succeeded
        case "failed": self = .failed
        case "refunded": self = .refunded
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .pending: "pending"
        case .requiresAction: "requires_action"
        case .succeeded: "succeeded"
        case .failed: "failed"
        case .refunded: "refunded"
        case .unknown(let value): value
        }
    }
}

public enum PaymentMethod: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case card
    case applePay
    case googlePay
    case azqr
    case cash
    case birbank
    case platform
    case unknown(String)

    public static let allCases: [PaymentMethod] = [.card, .applePay, .googlePay, .azqr, .cash, .birbank, .platform]

    public init(rawValue: String) {
        switch rawValue {
        case "card": self = .card
        case "apple_pay": self = .applePay
        case "google_pay": self = .googlePay
        case "azqr": self = .azqr
        case "cash": self = .cash
        case "birbank": self = .birbank
        case "platform": self = .platform
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .card: "card"
        case .applePay: "apple_pay"
        case .googlePay: "google_pay"
        case .azqr: "azqr"
        case .cash: "cash"
        case .birbank: "birbank"
        case .platform: "platform"
        case .unknown(let value): value
        }
    }
}

public enum PaymentTakenAt: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case till
    case guest
    case unknown(String)

    public static let allCases: [PaymentTakenAt] = [.till, .guest]

    public init(rawValue: String) {
        switch rawValue {
        case "till": self = .till
        case "guest": self = .guest
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .till: "till"
        case .guest: "guest"
        case .unknown(let value): value
        }
    }
}

public enum TableStatus: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case available
    case reserved
    case occupied
    case cleaning
    case payment
    case unknown(String)

    public static let allCases: [TableStatus] = [.available, .reserved, .occupied, .cleaning, .payment]

    public init(rawValue: String) {
        switch rawValue {
        case "available": self = .available
        case "reserved": self = .reserved
        case "occupied": self = .occupied
        case "cleaning": self = .cleaning
        case "payment": self = .payment
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .available: "available"
        case .reserved: "reserved"
        case .occupied: "occupied"
        case .cleaning: "cleaning"
        case .payment: "payment"
        case .unknown(let value): value
        }
    }
}

public enum LoyaltyProgramEarnBy: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case visit
    case items
    case unknown(String)

    public static let allCases: [LoyaltyProgramEarnBy] = [.visit, .items]

    public init(rawValue: String) {
        switch rawValue {
        case "visit": self = .visit
        case "items": self = .items
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .visit: "visit"
        case .items: "items"
        case .unknown(let value): value
        }
    }
}

public enum LoyaltyProgramRewardScope: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case all
    case categories
    case items
    case unknown(String)

    public static let allCases: [LoyaltyProgramRewardScope] = [.all, .categories, .items]

    public init(rawValue: String) {
        switch rawValue {
        case "all": self = .all
        case "categories": self = .categories
        case "items": self = .items
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .all: "all"
        case .categories: "categories"
        case .items: "items"
        case .unknown(let value): value
        }
    }
}

public enum LoyaltyCardSource: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case panel
    case till
    case web
    case app
    case unknown(String)

    public static let allCases: [LoyaltyCardSource] = [.panel, .till, .web, .app]

    public init(rawValue: String) {
        switch rawValue {
        case "panel": self = .panel
        case "till": self = .till
        case "web": self = .web
        case "app": self = .app
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .panel: "panel"
        case .till: "till"
        case .web: "web"
        case .app: "app"
        case .unknown(let value): value
        }
    }
}

public enum IngredientState: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case ok
    case low
    case empty
    case unknown(String)

    public static let allCases: [IngredientState] = [.ok, .low, .empty]

    public init(rawValue: String) {
        switch rawValue {
        case "ok": self = .ok
        case "low": self = .low
        case "empty": self = .empty
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .ok: "ok"
        case .low: "low"
        case .empty: "empty"
        case .unknown(let value): value
        }
    }
}

public enum SubscriptionStatus: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {
    case noSubscription
    case trial
    case active
    case expiring
    case grace
    case restricted
    case suspended
    case unknown(String)

    public static let allCases: [SubscriptionStatus] = [.noSubscription, .trial, .active, .expiring, .grace, .restricted, .suspended]

    public init(rawValue: String) {
        switch rawValue {
        case "none": self = .noSubscription
        case "trial": self = .trial
        case "active": self = .active
        case "expiring": self = .expiring
        case "grace": self = .grace
        case "restricted": self = .restricted
        case "suspended": self = .suspended
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .noSubscription: "none"
        case .trial: "trial"
        case .active: "active"
        case .expiring: "expiring"
        case .grace: "grace"
        case .restricted: "restricted"
        case .suspended: "suspended"
        case .unknown(let value): value
        }
    }
}
