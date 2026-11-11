import Foundation

public struct PreOrderLine: Hashable, Sendable, Codable {
    public var itemId: String
    public var qty: Int
    public var note: String?

    public init(itemId: String, qty: Int, note: String? = nil) {
        self.itemId = itemId
        self.qty = qty
        self.note = note
    }
}

public struct NewReservation: Hashable, Sendable, Codable {
    public var date: PlainDate
    public var time: String
    public var guests: Int
    public var guestName: String
    public var phone: String
    public var email: String?
    public var tableId: String?
    public var zone: String?
    public var specialRequest: String?
    public var allergyNote: String?
    public var birthday: Bool?
    public var childChair: Bool?
    public var preOrder: [PreOrderLine]?
    public var externalRef: String?

    public init(
        date: PlainDate,
        time: String,
        guests: Int,
        guestName: String,
        phone: String,
        email: String? = nil,
        tableId: String? = nil,
        zone: String? = nil,
        specialRequest: String? = nil,
        allergyNote: String? = nil,
        birthday: Bool? = nil,
        childChair: Bool? = nil,
        preOrder: [PreOrderLine]? = nil,
        externalRef: String? = nil
    ) {
        self.date = date
        self.time = time
        self.guests = guests
        self.guestName = guestName
        self.phone = phone
        self.email = email
        self.tableId = tableId
        self.zone = zone
        self.specialRequest = specialRequest
        self.allergyNote = allergyNote
        self.birthday = birthday
        self.childChair = childChair
        self.preOrder = preOrder
        self.externalRef = externalRef
    }
}

public struct CreateReservationResult: Hashable, Sendable {
    public let reservation: Reservation
    public let created: Bool

    public init(reservation: Reservation, created: Bool) {
        self.reservation = reservation
        self.created = created
    }
}
