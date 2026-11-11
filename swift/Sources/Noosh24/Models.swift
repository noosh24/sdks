import Foundation

public struct Restaurant: Noosh24Model {
    public let id: String?
    public let name: String?
    public let slug: String?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, slug: String? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.slug = slug
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, slug
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        slug = c.lenient(String.self, forKey: .slug)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(slug, forKey: .slug)
    }
}

public struct ApiKeyInfo: Noosh24Model {
    public let id: String?
    public let name: String?
    public let prefix: String?
    public let scopes: [String]?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, prefix: String? = nil, scopes: [String]? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.prefix = prefix
        self.scopes = scopes
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, prefix, scopes
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        prefix = c.lenient(String.self, forKey: .prefix)
        scopes = c.lenientList(String.self, forKey: .scopes)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(prefix, forKey: .prefix)
        try c.encodeIfPresent(scopes, forKey: .scopes)
    }
}

public struct Subscription: Noosh24Model {
    public let status: SubscriptionStatus?
    public let modules: [String]?
    public let raw: JSONValue?

    public init(status: SubscriptionStatus? = nil, modules: [String]? = nil, raw: JSONValue? = nil) {
        self.status = status
        self.modules = modules
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case status, modules
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.lenient(SubscriptionStatus.self, forKey: .status)
        modules = c.lenientList(String.self, forKey: .modules)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(modules, forKey: .modules)
    }
}

public struct Features: Noosh24Model {
    public let loyalty: Bool?
    public let inventory: Bool?
    public let raw: JSONValue?

    public init(loyalty: Bool? = nil, inventory: Bool? = nil, raw: JSONValue? = nil) {
        self.loyalty = loyalty
        self.inventory = inventory
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case loyalty, inventory
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        loyalty = c.lenient(Bool.self, forKey: .loyalty)
        inventory = c.lenient(Bool.self, forKey: .inventory)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(loyalty, forKey: .loyalty)
        try c.encodeIfPresent(inventory, forKey: .inventory)
    }
}

public struct Whoami: Noosh24Model {
    public let restaurant: Restaurant?
    public let key: ApiKeyInfo?
    public let subscription: Subscription?
    public let features: Features?
    public let raw: JSONValue?

    public init(restaurant: Restaurant? = nil, key: ApiKeyInfo? = nil, subscription: Subscription? = nil, features: Features? = nil, raw: JSONValue? = nil) {
        self.restaurant = restaurant
        self.key = key
        self.subscription = subscription
        self.features = features
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case restaurant, key, subscription, features
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        restaurant = c.lenient(Restaurant.self, forKey: .restaurant)
        key = c.lenient(ApiKeyInfo.self, forKey: .key)
        subscription = c.lenient(Subscription.self, forKey: .subscription)
        features = c.lenient(Features.self, forKey: .features)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(restaurant, forKey: .restaurant)
        try c.encodeIfPresent(key, forKey: .key)
        try c.encodeIfPresent(subscription, forKey: .subscription)
        try c.encodeIfPresent(features, forKey: .features)
    }
}

public struct Category: Noosh24Model {
    public let name: String?
    public let position: Int?
    public let products: Int?
    public let available: Int?
    public let raw: JSONValue?

    public init(name: String? = nil, position: Int? = nil, products: Int? = nil, available: Int? = nil, raw: JSONValue? = nil) {
        self.name = name
        self.position = position
        self.products = products
        self.available = available
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case name, position, products, available
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.lenient(String.self, forKey: .name)
        position = c.lenient(Int.self, forKey: .position)
        products = c.lenient(Int.self, forKey: .products)
        available = c.lenient(Int.self, forKey: .available)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(position, forKey: .position)
        try c.encodeIfPresent(products, forKey: .products)
        try c.encodeIfPresent(available, forKey: .available)
    }
}

public struct Modifier: Noosh24Model {
    public let id: String?
    public let name: String?
    public let priceDelta: Double?
    public let position: Int?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, priceDelta: Double? = nil, position: Int? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.priceDelta = priceDelta
        self.position = position
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, priceDelta, position
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        priceDelta = c.lenient(Double.self, forKey: .priceDelta)
        position = c.lenient(Int.self, forKey: .position)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(priceDelta, forKey: .priceDelta)
        try c.encodeIfPresent(position, forKey: .position)
    }
}

public struct ModifierGroup: Noosh24Model {
    public let id: String?
    public let name: String?
    public let required: Bool?
    public let position: Int?
    public let modifiers: [Modifier]?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, required: Bool? = nil, position: Int? = nil, modifiers: [Modifier]? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.required = required
        self.position = position
        self.modifiers = modifiers
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, required, position, modifiers
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        required = c.lenient(Bool.self, forKey: .required)
        position = c.lenient(Int.self, forKey: .position)
        modifiers = c.lenientList(Modifier.self, forKey: .modifiers)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(required, forKey: .required)
        try c.encodeIfPresent(position, forKey: .position)
        try c.encodeIfPresent(modifiers, forKey: .modifiers)
    }
}

public struct ProductTranslation: Noosh24Model {
    public let name: String?
    public let description: String?
    public let raw: JSONValue?

    public init(name: String? = nil, description: String? = nil, raw: JSONValue? = nil) {
        self.name = name
        self.description = description
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case name, description
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.lenient(String.self, forKey: .name)
        description = c.lenient(String.self, forKey: .description)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
    }
}

public struct Product: Noosh24Model {
    public let id: String?
    public let name: String?
    public let category: String?
    public let description: String?
    public let price: Double?
    public let available: Bool?
    public let popular: Bool?
    public let position: Int?
    public let prepMinutes: Int?
    public let station: String?
    public let vatRate: Double?
    public let vegetarian: Bool?
    public let spicy: Bool?
    public let allergens: [String]?
    public let discountable: Bool?
    public let hasModifiers: Bool?
    public let image: String?
    public let video: String?
    public let modifierGroups: [ModifierGroup]?
    public let translations: [String: ProductTranslation]?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, category: String? = nil, description: String? = nil, price: Double? = nil, available: Bool? = nil, popular: Bool? = nil, position: Int? = nil, prepMinutes: Int? = nil, station: String? = nil, vatRate: Double? = nil, vegetarian: Bool? = nil, spicy: Bool? = nil, allergens: [String]? = nil, discountable: Bool? = nil, hasModifiers: Bool? = nil, image: String? = nil, video: String? = nil, modifierGroups: [ModifierGroup]? = nil, translations: [String: ProductTranslation]? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.price = price
        self.available = available
        self.popular = popular
        self.position = position
        self.prepMinutes = prepMinutes
        self.station = station
        self.vatRate = vatRate
        self.vegetarian = vegetarian
        self.spicy = spicy
        self.allergens = allergens
        self.discountable = discountable
        self.hasModifiers = hasModifiers
        self.image = image
        self.video = video
        self.modifierGroups = modifierGroups
        self.translations = translations
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, description, price, available, popular, position, prepMinutes, station, vatRate, vegetarian, spicy, allergens, discountable, hasModifiers, image, video, modifierGroups, translations
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        category = c.lenient(String.self, forKey: .category)
        description = c.lenient(String.self, forKey: .description)
        price = c.lenient(Double.self, forKey: .price)
        available = c.lenient(Bool.self, forKey: .available)
        popular = c.lenient(Bool.self, forKey: .popular)
        position = c.lenient(Int.self, forKey: .position)
        prepMinutes = c.lenient(Int.self, forKey: .prepMinutes)
        station = c.lenient(String.self, forKey: .station)
        vatRate = c.lenient(Double.self, forKey: .vatRate)
        vegetarian = c.lenient(Bool.self, forKey: .vegetarian)
        spicy = c.lenient(Bool.self, forKey: .spicy)
        allergens = c.lenientList(String.self, forKey: .allergens)
        discountable = c.lenient(Bool.self, forKey: .discountable)
        hasModifiers = c.lenient(Bool.self, forKey: .hasModifiers)
        image = c.lenient(String.self, forKey: .image)
        video = c.lenient(String.self, forKey: .video)
        modifierGroups = c.lenientList(ModifierGroup.self, forKey: .modifierGroups)
        translations = c.lenientMap(ProductTranslation.self, forKey: .translations)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(category, forKey: .category)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(price, forKey: .price)
        try c.encodeIfPresent(available, forKey: .available)
        try c.encodeIfPresent(popular, forKey: .popular)
        try c.encodeIfPresent(position, forKey: .position)
        try c.encodeIfPresent(prepMinutes, forKey: .prepMinutes)
        try c.encodeIfPresent(station, forKey: .station)
        try c.encodeIfPresent(vatRate, forKey: .vatRate)
        try c.encodeIfPresent(vegetarian, forKey: .vegetarian)
        try c.encodeIfPresent(spicy, forKey: .spicy)
        try c.encodeIfPresent(allergens, forKey: .allergens)
        try c.encodeIfPresent(discountable, forKey: .discountable)
        try c.encodeIfPresent(hasModifiers, forKey: .hasModifiers)
        try c.encodeIfPresent(image, forKey: .image)
        try c.encodeIfPresent(video, forKey: .video)
        try c.encodeIfPresent(modifierGroups, forKey: .modifierGroups)
        try c.encodeIfPresent(translations, forKey: .translations)
    }
}

public struct StopListItem: Noosh24Model {
    public let id: String?
    public let name: String?
    public let category: String?
    public let price: Double?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, category: String? = nil, price: Double? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.price = price
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, price
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        category = c.lenient(String.self, forKey: .category)
        price = c.lenient(Double.self, forKey: .price)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(category, forKey: .category)
        try c.encodeIfPresent(price, forKey: .price)
    }
}

public struct ReservationGuest: Noosh24Model {
    public let name: String?
    public let phone: String?
    public let email: String?
    public let raw: JSONValue?

    public init(name: String? = nil, phone: String? = nil, email: String? = nil, raw: JSONValue? = nil) {
        self.name = name
        self.phone = phone
        self.email = email
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case name, phone, email
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.lenient(String.self, forKey: .name)
        phone = c.lenient(String.self, forKey: .phone)
        email = c.lenient(String.self, forKey: .email)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(phone, forKey: .phone)
        try c.encodeIfPresent(email, forKey: .email)
    }
}

public struct ReservationTable: Noosh24Model {
    public let id: String?
    public let label: String?
    public let raw: JSONValue?

    public init(id: String? = nil, label: String? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.label = label
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, label
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        label = c.lenient(String.self, forKey: .label)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(label, forKey: .label)
    }
}

public struct ReservationPreOrderItem: Noosh24Model {
    public let productId: String?
    public let name: String?
    public let price: Double?
    public let qty: Int?
    public let note: String?
    public let raw: JSONValue?

    public init(productId: String? = nil, name: String? = nil, price: Double? = nil, qty: Int? = nil, note: String? = nil, raw: JSONValue? = nil) {
        self.productId = productId
        self.name = name
        self.price = price
        self.qty = qty
        self.note = note
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case productId, name, price, qty, note
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        productId = c.lenient(String.self, forKey: .productId)
        name = c.lenient(String.self, forKey: .name)
        price = c.lenient(Double.self, forKey: .price)
        qty = c.lenient(Int.self, forKey: .qty)
        note = c.lenient(String.self, forKey: .note)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(productId, forKey: .productId)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(price, forKey: .price)
        try c.encodeIfPresent(qty, forKey: .qty)
        try c.encodeIfPresent(note, forKey: .note)
    }
}

public struct Reservation: Noosh24Model {
    public let id: String?
    public let code: String?
    public let status: ReservationStatus?
    public let source: ReservationSource?
    public let startsAt: Date?
    public let endsAt: Date?
    public let guests: Int?
    public let zone: String?
    public let table: ReservationTable?
    public let guest: ReservationGuest?
    public let specialRequest: String?
    public let allergyNote: String?
    public let birthday: Bool?
    public let childChair: Bool?
    public let depositPaid: Double?
    public let preOrder: [ReservationPreOrderItem]?
    public let externalRef: String?
    public let decidedAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let raw: JSONValue?

    public init(id: String? = nil, code: String? = nil, status: ReservationStatus? = nil, source: ReservationSource? = nil, startsAt: Date? = nil, endsAt: Date? = nil, guests: Int? = nil, zone: String? = nil, table: ReservationTable? = nil, guest: ReservationGuest? = nil, specialRequest: String? = nil, allergyNote: String? = nil, birthday: Bool? = nil, childChair: Bool? = nil, depositPaid: Double? = nil, preOrder: [ReservationPreOrderItem]? = nil, externalRef: String? = nil, decidedAt: Date? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.code = code
        self.status = status
        self.source = source
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.guests = guests
        self.zone = zone
        self.table = table
        self.guest = guest
        self.specialRequest = specialRequest
        self.allergyNote = allergyNote
        self.birthday = birthday
        self.childChair = childChair
        self.depositPaid = depositPaid
        self.preOrder = preOrder
        self.externalRef = externalRef
        self.decidedAt = decidedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, code, status, source, startsAt, endsAt, guests, zone, table, guest, specialRequest, allergyNote, birthday, childChair, depositPaid, preOrder, externalRef, decidedAt, createdAt, updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        code = c.lenient(String.self, forKey: .code)
        status = c.lenient(ReservationStatus.self, forKey: .status)
        source = c.lenient(ReservationSource.self, forKey: .source)
        startsAt = c.lenientDate(forKey: .startsAt)
        endsAt = c.lenientDate(forKey: .endsAt)
        guests = c.lenient(Int.self, forKey: .guests)
        zone = c.lenient(String.self, forKey: .zone)
        table = c.lenient(ReservationTable.self, forKey: .table)
        guest = c.lenient(ReservationGuest.self, forKey: .guest)
        specialRequest = c.lenient(String.self, forKey: .specialRequest)
        allergyNote = c.lenient(String.self, forKey: .allergyNote)
        birthday = c.lenient(Bool.self, forKey: .birthday)
        childChair = c.lenient(Bool.self, forKey: .childChair)
        depositPaid = c.lenient(Double.self, forKey: .depositPaid)
        preOrder = c.lenientList(ReservationPreOrderItem.self, forKey: .preOrder)
        externalRef = c.lenient(String.self, forKey: .externalRef)
        decidedAt = c.lenientDate(forKey: .decidedAt)
        createdAt = c.lenientDate(forKey: .createdAt)
        updatedAt = c.lenientDate(forKey: .updatedAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(code, forKey: .code)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(source, forKey: .source)
        try c.encodeIfPresent(startsAt, forKey: .startsAt)
        try c.encodeIfPresent(endsAt, forKey: .endsAt)
        try c.encodeIfPresent(guests, forKey: .guests)
        try c.encodeIfPresent(zone, forKey: .zone)
        try c.encodeIfPresent(table, forKey: .table)
        try c.encodeIfPresent(guest, forKey: .guest)
        try c.encodeIfPresent(specialRequest, forKey: .specialRequest)
        try c.encodeIfPresent(allergyNote, forKey: .allergyNote)
        try c.encodeIfPresent(birthday, forKey: .birthday)
        try c.encodeIfPresent(childChair, forKey: .childChair)
        try c.encodeIfPresent(depositPaid, forKey: .depositPaid)
        try c.encodeIfPresent(preOrder, forKey: .preOrder)
        try c.encodeIfPresent(externalRef, forKey: .externalRef)
        try c.encodeIfPresent(decidedAt, forKey: .decidedAt)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

public struct AvailableTable: Noosh24Model {
    public let id: String?
    public let label: String?
    public let hallId: String?
    public let zone: String?
    public let seats: Int?
    public let free: Bool?
    public let raw: JSONValue?

    public init(id: String? = nil, label: String? = nil, hallId: String? = nil, zone: String? = nil, seats: Int? = nil, free: Bool? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.label = label
        self.hallId = hallId
        self.zone = zone
        self.seats = seats
        self.free = free
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, label, hallId, zone, seats, free
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        label = c.lenient(String.self, forKey: .label)
        hallId = c.lenient(String.self, forKey: .hallId)
        zone = c.lenient(String.self, forKey: .zone)
        seats = c.lenient(Int.self, forKey: .seats)
        free = c.lenient(Bool.self, forKey: .free)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(label, forKey: .label)
        try c.encodeIfPresent(hallId, forKey: .hallId)
        try c.encodeIfPresent(zone, forKey: .zone)
        try c.encodeIfPresent(seats, forKey: .seats)
        try c.encodeIfPresent(free, forKey: .free)
    }
}

public struct TableAvailability: Noosh24Model {
    public let startsAt: Date?
    public let endsAt: Date?
    public let durationMinutes: Int?
    public let openTime: String?
    public let closeTime: String?
    public let tables: [AvailableTable]?
    public let raw: JSONValue?

    public init(startsAt: Date? = nil, endsAt: Date? = nil, durationMinutes: Int? = nil, openTime: String? = nil, closeTime: String? = nil, tables: [AvailableTable]? = nil, raw: JSONValue? = nil) {
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.durationMinutes = durationMinutes
        self.openTime = openTime
        self.closeTime = closeTime
        self.tables = tables
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case startsAt, endsAt, durationMinutes, openTime, closeTime, tables
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        startsAt = c.lenientDate(forKey: .startsAt)
        endsAt = c.lenientDate(forKey: .endsAt)
        durationMinutes = c.lenient(Int.self, forKey: .durationMinutes)
        openTime = c.lenient(String.self, forKey: .openTime)
        closeTime = c.lenient(String.self, forKey: .closeTime)
        tables = c.lenientList(AvailableTable.self, forKey: .tables)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(startsAt, forKey: .startsAt)
        try c.encodeIfPresent(endsAt, forKey: .endsAt)
        try c.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
        try c.encodeIfPresent(openTime, forKey: .openTime)
        try c.encodeIfPresent(closeTime, forKey: .closeTime)
        try c.encodeIfPresent(tables, forKey: .tables)
    }
}

public struct OrderItem: Noosh24Model {
    public let id: String?
    public let productId: String?
    public let name: String?
    public let qty: Int?
    public let price: Double?
    public let listPrice: Double?
    public let modifiers: String?
    public let note: String?
    public let status: OrderItemStatus?
    public let comp: Bool?
    public let campaign: String?
    public let cancelReason: String?
    public let raw: JSONValue?

    public init(id: String? = nil, productId: String? = nil, name: String? = nil, qty: Int? = nil, price: Double? = nil, listPrice: Double? = nil, modifiers: String? = nil, note: String? = nil, status: OrderItemStatus? = nil, comp: Bool? = nil, campaign: String? = nil, cancelReason: String? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.productId = productId
        self.name = name
        self.qty = qty
        self.price = price
        self.listPrice = listPrice
        self.modifiers = modifiers
        self.note = note
        self.status = status
        self.comp = comp
        self.campaign = campaign
        self.cancelReason = cancelReason
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, productId, name, qty, price, listPrice, modifiers, note, status, comp, campaign, cancelReason
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        productId = c.lenient(String.self, forKey: .productId)
        name = c.lenient(String.self, forKey: .name)
        qty = c.lenient(Int.self, forKey: .qty)
        price = c.lenient(Double.self, forKey: .price)
        listPrice = c.lenient(Double.self, forKey: .listPrice)
        modifiers = c.lenient(String.self, forKey: .modifiers)
        note = c.lenient(String.self, forKey: .note)
        status = c.lenient(OrderItemStatus.self, forKey: .status)
        comp = c.lenient(Bool.self, forKey: .comp)
        campaign = c.lenient(String.self, forKey: .campaign)
        cancelReason = c.lenient(String.self, forKey: .cancelReason)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(productId, forKey: .productId)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(qty, forKey: .qty)
        try c.encodeIfPresent(price, forKey: .price)
        try c.encodeIfPresent(listPrice, forKey: .listPrice)
        try c.encodeIfPresent(modifiers, forKey: .modifiers)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(comp, forKey: .comp)
        try c.encodeIfPresent(campaign, forKey: .campaign)
        try c.encodeIfPresent(cancelReason, forKey: .cancelReason)
    }
}

public struct DeliveryPlatform: Noosh24Model {
    public let id: String?
    public let name: String?
    public let ref: String?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, ref: String? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.ref = ref
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, ref
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        ref = c.lenient(String.self, forKey: .ref)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(ref, forKey: .ref)
    }
}

public struct OrderDelivery: Noosh24Model {
    public let status: String?
    public let platform: DeliveryPlatform?
    public let address: String?
    public let customerPhone: String?
    public let courierName: String?
    public let note: String?
    public let paymentMethod: String?
    public let fee: Double?
    public let platformTotal: Double?
    public let acceptedAt: Date?
    public let raw: JSONValue?

    public init(status: String? = nil, platform: DeliveryPlatform? = nil, address: String? = nil, customerPhone: String? = nil, courierName: String? = nil, note: String? = nil, paymentMethod: String? = nil, fee: Double? = nil, platformTotal: Double? = nil, acceptedAt: Date? = nil, raw: JSONValue? = nil) {
        self.status = status
        self.platform = platform
        self.address = address
        self.customerPhone = customerPhone
        self.courierName = courierName
        self.note = note
        self.paymentMethod = paymentMethod
        self.fee = fee
        self.platformTotal = platformTotal
        self.acceptedAt = acceptedAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case status, platform, address, customerPhone, courierName, note, paymentMethod, fee, platformTotal, acceptedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.lenient(String.self, forKey: .status)
        platform = c.lenient(DeliveryPlatform.self, forKey: .platform)
        address = c.lenient(String.self, forKey: .address)
        customerPhone = c.lenient(String.self, forKey: .customerPhone)
        courierName = c.lenient(String.self, forKey: .courierName)
        note = c.lenient(String.self, forKey: .note)
        paymentMethod = c.lenient(String.self, forKey: .paymentMethod)
        fee = c.lenient(Double.self, forKey: .fee)
        platformTotal = c.lenient(Double.self, forKey: .platformTotal)
        acceptedAt = c.lenientDate(forKey: .acceptedAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(platform, forKey: .platform)
        try c.encodeIfPresent(address, forKey: .address)
        try c.encodeIfPresent(customerPhone, forKey: .customerPhone)
        try c.encodeIfPresent(courierName, forKey: .courierName)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encodeIfPresent(paymentMethod, forKey: .paymentMethod)
        try c.encodeIfPresent(fee, forKey: .fee)
        try c.encodeIfPresent(platformTotal, forKey: .platformTotal)
        try c.encodeIfPresent(acceptedAt, forKey: .acceptedAt)
    }
}

public struct Order: Noosh24Model {
    public let id: String?
    public let number: String?
    public let dailyNumber: Int?
    public let kind: OrderKind?
    public let orderType: String?
    public let status: OrderStatus?
    public let tableId: String?
    public let billId: String?
    public let customerName: String?
    public let allergyNote: String?
    public let items: [OrderItem]?
    public let subtotal: Double?
    public let delivery: OrderDelivery?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let raw: JSONValue?

    public init(id: String? = nil, number: String? = nil, dailyNumber: Int? = nil, kind: OrderKind? = nil, orderType: String? = nil, status: OrderStatus? = nil, tableId: String? = nil, billId: String? = nil, customerName: String? = nil, allergyNote: String? = nil, items: [OrderItem]? = nil, subtotal: Double? = nil, delivery: OrderDelivery? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.number = number
        self.dailyNumber = dailyNumber
        self.kind = kind
        self.orderType = orderType
        self.status = status
        self.tableId = tableId
        self.billId = billId
        self.customerName = customerName
        self.allergyNote = allergyNote
        self.items = items
        self.subtotal = subtotal
        self.delivery = delivery
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, number, dailyNumber, kind, orderType, status, tableId, billId, customerName, allergyNote, items, subtotal, delivery, createdAt, updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        number = c.lenient(String.self, forKey: .number)
        dailyNumber = c.lenient(Int.self, forKey: .dailyNumber)
        kind = c.lenient(OrderKind.self, forKey: .kind)
        orderType = c.lenient(String.self, forKey: .orderType)
        status = c.lenient(OrderStatus.self, forKey: .status)
        tableId = c.lenient(String.self, forKey: .tableId)
        billId = c.lenient(String.self, forKey: .billId)
        customerName = c.lenient(String.self, forKey: .customerName)
        allergyNote = c.lenient(String.self, forKey: .allergyNote)
        items = c.lenientList(OrderItem.self, forKey: .items)
        subtotal = c.lenient(Double.self, forKey: .subtotal)
        delivery = c.lenient(OrderDelivery.self, forKey: .delivery)
        createdAt = c.lenientDate(forKey: .createdAt)
        updatedAt = c.lenientDate(forKey: .updatedAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(number, forKey: .number)
        try c.encodeIfPresent(dailyNumber, forKey: .dailyNumber)
        try c.encodeIfPresent(kind, forKey: .kind)
        try c.encodeIfPresent(orderType, forKey: .orderType)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(tableId, forKey: .tableId)
        try c.encodeIfPresent(billId, forKey: .billId)
        try c.encodeIfPresent(customerName, forKey: .customerName)
        try c.encodeIfPresent(allergyNote, forKey: .allergyNote)
        try c.encodeIfPresent(items, forKey: .items)
        try c.encodeIfPresent(subtotal, forKey: .subtotal)
        try c.encodeIfPresent(delivery, forKey: .delivery)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

public struct Bill: Noosh24Model {
    public let id: String?
    public let tableId: String?
    public let status: BillStatus?
    public let guests: Int?
    public let waiter: String?
    public let customerId: String?
    public let reservationId: String?
    public let orderIds: [String]?
    public let subtotal: Double?
    public let discountPercent: Double?
    public let billDiscount: Double?
    public let serviceFeePercent: Double?
    public let serviceFee: Double?
    public let total: Double?
    public let paid: Double?
    public let remaining: Double?
    public let openedAt: Date?
    public let closedAt: Date?
    public let raw: JSONValue?

    public init(id: String? = nil, tableId: String? = nil, status: BillStatus? = nil, guests: Int? = nil, waiter: String? = nil, customerId: String? = nil, reservationId: String? = nil, orderIds: [String]? = nil, subtotal: Double? = nil, discountPercent: Double? = nil, billDiscount: Double? = nil, serviceFeePercent: Double? = nil, serviceFee: Double? = nil, total: Double? = nil, paid: Double? = nil, remaining: Double? = nil, openedAt: Date? = nil, closedAt: Date? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.tableId = tableId
        self.status = status
        self.guests = guests
        self.waiter = waiter
        self.customerId = customerId
        self.reservationId = reservationId
        self.orderIds = orderIds
        self.subtotal = subtotal
        self.discountPercent = discountPercent
        self.billDiscount = billDiscount
        self.serviceFeePercent = serviceFeePercent
        self.serviceFee = serviceFee
        self.total = total
        self.paid = paid
        self.remaining = remaining
        self.openedAt = openedAt
        self.closedAt = closedAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, tableId, status, guests, waiter, customerId, reservationId, orderIds, subtotal, discountPercent, billDiscount, serviceFeePercent, serviceFee, total, paid, remaining, openedAt, closedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        tableId = c.lenient(String.self, forKey: .tableId)
        status = c.lenient(BillStatus.self, forKey: .status)
        guests = c.lenient(Int.self, forKey: .guests)
        waiter = c.lenient(String.self, forKey: .waiter)
        customerId = c.lenient(String.self, forKey: .customerId)
        reservationId = c.lenient(String.self, forKey: .reservationId)
        orderIds = c.lenientList(String.self, forKey: .orderIds)
        subtotal = c.lenient(Double.self, forKey: .subtotal)
        discountPercent = c.lenient(Double.self, forKey: .discountPercent)
        billDiscount = c.lenient(Double.self, forKey: .billDiscount)
        serviceFeePercent = c.lenient(Double.self, forKey: .serviceFeePercent)
        serviceFee = c.lenient(Double.self, forKey: .serviceFee)
        total = c.lenient(Double.self, forKey: .total)
        paid = c.lenient(Double.self, forKey: .paid)
        remaining = c.lenient(Double.self, forKey: .remaining)
        openedAt = c.lenientDate(forKey: .openedAt)
        closedAt = c.lenientDate(forKey: .closedAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(tableId, forKey: .tableId)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(guests, forKey: .guests)
        try c.encodeIfPresent(waiter, forKey: .waiter)
        try c.encodeIfPresent(customerId, forKey: .customerId)
        try c.encodeIfPresent(reservationId, forKey: .reservationId)
        try c.encodeIfPresent(orderIds, forKey: .orderIds)
        try c.encodeIfPresent(subtotal, forKey: .subtotal)
        try c.encodeIfPresent(discountPercent, forKey: .discountPercent)
        try c.encodeIfPresent(billDiscount, forKey: .billDiscount)
        try c.encodeIfPresent(serviceFeePercent, forKey: .serviceFeePercent)
        try c.encodeIfPresent(serviceFee, forKey: .serviceFee)
        try c.encodeIfPresent(total, forKey: .total)
        try c.encodeIfPresent(paid, forKey: .paid)
        try c.encodeIfPresent(remaining, forKey: .remaining)
        try c.encodeIfPresent(openedAt, forKey: .openedAt)
        try c.encodeIfPresent(closedAt, forKey: .closedAt)
    }
}

public struct PaymentCard: Noosh24Model {
    public let maskedPan: String?
    public let scheme: String?
    public let bank: String?
    public let raw: JSONValue?

    public init(maskedPan: String? = nil, scheme: String? = nil, bank: String? = nil, raw: JSONValue? = nil) {
        self.maskedPan = maskedPan
        self.scheme = scheme
        self.bank = bank
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case maskedPan, scheme, bank
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        maskedPan = c.lenient(String.self, forKey: .maskedPan)
        scheme = c.lenient(String.self, forKey: .scheme)
        bank = c.lenient(String.self, forKey: .bank)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(maskedPan, forKey: .maskedPan)
        try c.encodeIfPresent(scheme, forKey: .scheme)
        try c.encodeIfPresent(bank, forKey: .bank)
    }
}

public struct PaymentPlatform: Noosh24Model {
    public let id: String?
    public let name: String?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
    }
}

public struct Payment: Noosh24Model {
    public let id: String?
    public let status: PaymentStatus?
    public let method: PaymentMethod?
    public let recordedMethod: String?
    public let amount: Double?
    public let tip: Double?
    public let refundedAmount: Double?
    public let refundedAt: Date?
    public let refundReason: String?
    public let billId: String?
    public let reservationId: String?
    public let orderId: String?
    public let takenAt: PaymentTakenAt?
    public let card: PaymentCard?
    public let platform: PaymentPlatform?
    public let createdAt: Date?
    public let settledAt: Date?
    public let raw: JSONValue?

    public init(id: String? = nil, status: PaymentStatus? = nil, method: PaymentMethod? = nil, recordedMethod: String? = nil, amount: Double? = nil, tip: Double? = nil, refundedAmount: Double? = nil, refundedAt: Date? = nil, refundReason: String? = nil, billId: String? = nil, reservationId: String? = nil, orderId: String? = nil, takenAt: PaymentTakenAt? = nil, card: PaymentCard? = nil, platform: PaymentPlatform? = nil, createdAt: Date? = nil, settledAt: Date? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.status = status
        self.method = method
        self.recordedMethod = recordedMethod
        self.amount = amount
        self.tip = tip
        self.refundedAmount = refundedAmount
        self.refundedAt = refundedAt
        self.refundReason = refundReason
        self.billId = billId
        self.reservationId = reservationId
        self.orderId = orderId
        self.takenAt = takenAt
        self.card = card
        self.platform = platform
        self.createdAt = createdAt
        self.settledAt = settledAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, status, method, recordedMethod, amount, tip, refundedAmount, refundedAt, refundReason, billId, reservationId, orderId, takenAt, card, platform, createdAt, settledAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        status = c.lenient(PaymentStatus.self, forKey: .status)
        method = c.lenient(PaymentMethod.self, forKey: .method)
        recordedMethod = c.lenient(String.self, forKey: .recordedMethod)
        amount = c.lenient(Double.self, forKey: .amount)
        tip = c.lenient(Double.self, forKey: .tip)
        refundedAmount = c.lenient(Double.self, forKey: .refundedAmount)
        refundedAt = c.lenientDate(forKey: .refundedAt)
        refundReason = c.lenient(String.self, forKey: .refundReason)
        billId = c.lenient(String.self, forKey: .billId)
        reservationId = c.lenient(String.self, forKey: .reservationId)
        orderId = c.lenient(String.self, forKey: .orderId)
        takenAt = c.lenient(PaymentTakenAt.self, forKey: .takenAt)
        card = c.lenient(PaymentCard.self, forKey: .card)
        platform = c.lenient(PaymentPlatform.self, forKey: .platform)
        createdAt = c.lenientDate(forKey: .createdAt)
        settledAt = c.lenientDate(forKey: .settledAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(method, forKey: .method)
        try c.encodeIfPresent(recordedMethod, forKey: .recordedMethod)
        try c.encodeIfPresent(amount, forKey: .amount)
        try c.encodeIfPresent(tip, forKey: .tip)
        try c.encodeIfPresent(refundedAmount, forKey: .refundedAmount)
        try c.encodeIfPresent(refundedAt, forKey: .refundedAt)
        try c.encodeIfPresent(refundReason, forKey: .refundReason)
        try c.encodeIfPresent(billId, forKey: .billId)
        try c.encodeIfPresent(reservationId, forKey: .reservationId)
        try c.encodeIfPresent(orderId, forKey: .orderId)
        try c.encodeIfPresent(takenAt, forKey: .takenAt)
        try c.encodeIfPresent(card, forKey: .card)
        try c.encodeIfPresent(platform, forKey: .platform)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(settledAt, forKey: .settledAt)
    }
}

public struct Hall: Noosh24Model {
    public let id: String?
    public let name: String?
    public let position: Int?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, position: Int? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.position = position
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, position
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        position = c.lenient(Int.self, forKey: .position)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(position, forKey: .position)
    }
}

public struct Table: Noosh24Model {
    public let id: String?
    public let label: String?
    public let hallId: String?
    public let zone: String?
    public let seats: Int?
    public let shape: String?
    public let status: TableStatus?
    public let guests: Int?
    public let waiter: String?
    public let seatedSince: String?
    public let openOrders: Int?
    public let billId: String?
    public let billTotal: Double?
    public let billRequested: Bool?
    public let billSettled: Bool?
    public let mergedInto: String?
    public let raw: JSONValue?

    public init(id: String? = nil, label: String? = nil, hallId: String? = nil, zone: String? = nil, seats: Int? = nil, shape: String? = nil, status: TableStatus? = nil, guests: Int? = nil, waiter: String? = nil, seatedSince: String? = nil, openOrders: Int? = nil, billId: String? = nil, billTotal: Double? = nil, billRequested: Bool? = nil, billSettled: Bool? = nil, mergedInto: String? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.label = label
        self.hallId = hallId
        self.zone = zone
        self.seats = seats
        self.shape = shape
        self.status = status
        self.guests = guests
        self.waiter = waiter
        self.seatedSince = seatedSince
        self.openOrders = openOrders
        self.billId = billId
        self.billTotal = billTotal
        self.billRequested = billRequested
        self.billSettled = billSettled
        self.mergedInto = mergedInto
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, label, hallId, zone, seats, shape, status, guests, waiter, seatedSince, openOrders, billId, billTotal, billRequested, billSettled, mergedInto
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        label = c.lenient(String.self, forKey: .label)
        hallId = c.lenient(String.self, forKey: .hallId)
        zone = c.lenient(String.self, forKey: .zone)
        seats = c.lenient(Int.self, forKey: .seats)
        shape = c.lenient(String.self, forKey: .shape)
        status = c.lenient(TableStatus.self, forKey: .status)
        guests = c.lenient(Int.self, forKey: .guests)
        waiter = c.lenient(String.self, forKey: .waiter)
        seatedSince = c.lenient(String.self, forKey: .seatedSince)
        openOrders = c.lenient(Int.self, forKey: .openOrders)
        billId = c.lenient(String.self, forKey: .billId)
        billTotal = c.lenient(Double.self, forKey: .billTotal)
        billRequested = c.lenient(Bool.self, forKey: .billRequested)
        billSettled = c.lenient(Bool.self, forKey: .billSettled)
        mergedInto = c.lenient(String.self, forKey: .mergedInto)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(label, forKey: .label)
        try c.encodeIfPresent(hallId, forKey: .hallId)
        try c.encodeIfPresent(zone, forKey: .zone)
        try c.encodeIfPresent(seats, forKey: .seats)
        try c.encodeIfPresent(shape, forKey: .shape)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(guests, forKey: .guests)
        try c.encodeIfPresent(waiter, forKey: .waiter)
        try c.encodeIfPresent(seatedSince, forKey: .seatedSince)
        try c.encodeIfPresent(openOrders, forKey: .openOrders)
        try c.encodeIfPresent(billId, forKey: .billId)
        try c.encodeIfPresent(billTotal, forKey: .billTotal)
        try c.encodeIfPresent(billRequested, forKey: .billRequested)
        try c.encodeIfPresent(billSettled, forKey: .billSettled)
        try c.encodeIfPresent(mergedInto, forKey: .mergedInto)
    }
}

public struct Customer: Noosh24Model {
    public let id: String?
    public let name: String?
    public let phone: String?
    public let note: String?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, phone: String? = nil, note: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.phone = phone
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, phone, note, createdAt, updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        phone = c.lenient(String.self, forKey: .phone)
        note = c.lenient(String.self, forKey: .note)
        createdAt = c.lenientDate(forKey: .createdAt)
        updatedAt = c.lenientDate(forKey: .updatedAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(phone, forKey: .phone)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

public struct LoyaltyProgram: Noosh24Model {
    public let stampsNeeded: Int?
    public let earnBy: LoyaltyProgramEarnBy?
    public let minBill: Double?
    public let oncePerDay: Bool?
    public let rewardName: String?
    public let rewardScope: LoyaltyProgramRewardScope?
    public let rewardCategories: [String]?
    public let rewardProductIds: [String]?
    public let rewardMaxPrice: Double?
    public let terms: String?
    public let raw: JSONValue?

    public init(stampsNeeded: Int? = nil, earnBy: LoyaltyProgramEarnBy? = nil, minBill: Double? = nil, oncePerDay: Bool? = nil, rewardName: String? = nil, rewardScope: LoyaltyProgramRewardScope? = nil, rewardCategories: [String]? = nil, rewardProductIds: [String]? = nil, rewardMaxPrice: Double? = nil, terms: String? = nil, raw: JSONValue? = nil) {
        self.stampsNeeded = stampsNeeded
        self.earnBy = earnBy
        self.minBill = minBill
        self.oncePerDay = oncePerDay
        self.rewardName = rewardName
        self.rewardScope = rewardScope
        self.rewardCategories = rewardCategories
        self.rewardProductIds = rewardProductIds
        self.rewardMaxPrice = rewardMaxPrice
        self.terms = terms
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case stampsNeeded, earnBy, minBill, oncePerDay, rewardName, rewardScope, rewardCategories, rewardProductIds, rewardMaxPrice, terms
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stampsNeeded = c.lenient(Int.self, forKey: .stampsNeeded)
        earnBy = c.lenient(LoyaltyProgramEarnBy.self, forKey: .earnBy)
        minBill = c.lenient(Double.self, forKey: .minBill)
        oncePerDay = c.lenient(Bool.self, forKey: .oncePerDay)
        rewardName = c.lenient(String.self, forKey: .rewardName)
        rewardScope = c.lenient(LoyaltyProgramRewardScope.self, forKey: .rewardScope)
        rewardCategories = c.lenientList(String.self, forKey: .rewardCategories)
        rewardProductIds = c.lenientList(String.self, forKey: .rewardProductIds)
        rewardMaxPrice = c.lenient(Double.self, forKey: .rewardMaxPrice)
        terms = c.lenient(String.self, forKey: .terms)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(stampsNeeded, forKey: .stampsNeeded)
        try c.encodeIfPresent(earnBy, forKey: .earnBy)
        try c.encodeIfPresent(minBill, forKey: .minBill)
        try c.encodeIfPresent(oncePerDay, forKey: .oncePerDay)
        try c.encodeIfPresent(rewardName, forKey: .rewardName)
        try c.encodeIfPresent(rewardScope, forKey: .rewardScope)
        try c.encodeIfPresent(rewardCategories, forKey: .rewardCategories)
        try c.encodeIfPresent(rewardProductIds, forKey: .rewardProductIds)
        try c.encodeIfPresent(rewardMaxPrice, forKey: .rewardMaxPrice)
        try c.encodeIfPresent(terms, forKey: .terms)
    }
}

public struct LoyaltyCard: Noosh24Model {
    public let id: String?
    public let name: String?
    public let phone: String?
    public let stamps: Int?
    public let totalStamps: Int?
    public let redeemed: Int?
    public let source: LoyaltyCardSource?
    public let lastVisitAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, phone: String? = nil, stamps: Int? = nil, totalStamps: Int? = nil, redeemed: Int? = nil, source: LoyaltyCardSource? = nil, lastVisitAt: Date? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.phone = phone
        self.stamps = stamps
        self.totalStamps = totalStamps
        self.redeemed = redeemed
        self.source = source
        self.lastVisitAt = lastVisitAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, phone, stamps, totalStamps, redeemed, source, lastVisitAt, createdAt, updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        phone = c.lenient(String.self, forKey: .phone)
        stamps = c.lenient(Int.self, forKey: .stamps)
        totalStamps = c.lenient(Int.self, forKey: .totalStamps)
        redeemed = c.lenient(Int.self, forKey: .redeemed)
        source = c.lenient(LoyaltyCardSource.self, forKey: .source)
        lastVisitAt = c.lenientDate(forKey: .lastVisitAt)
        createdAt = c.lenientDate(forKey: .createdAt)
        updatedAt = c.lenientDate(forKey: .updatedAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(phone, forKey: .phone)
        try c.encodeIfPresent(stamps, forKey: .stamps)
        try c.encodeIfPresent(totalStamps, forKey: .totalStamps)
        try c.encodeIfPresent(redeemed, forKey: .redeemed)
        try c.encodeIfPresent(source, forKey: .source)
        try c.encodeIfPresent(lastVisitAt, forKey: .lastVisitAt)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

public struct Ingredient: Noosh24Model {
    public let id: String?
    public let name: String?
    public let unit: String?
    public let stock: Double?
    public let onOpenBills: Double?
    public let available: Double?
    public let state: IngredientState?
    public let lowStock: Double?
    public let parStock: Double?
    public let costPerUnit: Double?
    public let value: Double?
    public let prepared: Bool?
    public let byStore: [String: Double]?
    public let updatedAt: Date?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, unit: String? = nil, stock: Double? = nil, onOpenBills: Double? = nil, available: Double? = nil, state: IngredientState? = nil, lowStock: Double? = nil, parStock: Double? = nil, costPerUnit: Double? = nil, value: Double? = nil, prepared: Bool? = nil, byStore: [String: Double]? = nil, updatedAt: Date? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.unit = unit
        self.stock = stock
        self.onOpenBills = onOpenBills
        self.available = available
        self.state = state
        self.lowStock = lowStock
        self.parStock = parStock
        self.costPerUnit = costPerUnit
        self.value = value
        self.prepared = prepared
        self.byStore = byStore
        self.updatedAt = updatedAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, unit, stock, onOpenBills, available, state, lowStock, parStock, costPerUnit, value, prepared, byStore, updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        unit = c.lenient(String.self, forKey: .unit)
        stock = c.lenient(Double.self, forKey: .stock)
        onOpenBills = c.lenient(Double.self, forKey: .onOpenBills)
        available = c.lenient(Double.self, forKey: .available)
        state = c.lenient(IngredientState.self, forKey: .state)
        lowStock = c.lenient(Double.self, forKey: .lowStock)
        parStock = c.lenient(Double.self, forKey: .parStock)
        costPerUnit = c.lenient(Double.self, forKey: .costPerUnit)
        value = c.lenient(Double.self, forKey: .value)
        prepared = c.lenient(Bool.self, forKey: .prepared)
        byStore = c.lenientMap(Double.self, forKey: .byStore)
        updatedAt = c.lenientDate(forKey: .updatedAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(unit, forKey: .unit)
        try c.encodeIfPresent(stock, forKey: .stock)
        try c.encodeIfPresent(onOpenBills, forKey: .onOpenBills)
        try c.encodeIfPresent(available, forKey: .available)
        try c.encodeIfPresent(state, forKey: .state)
        try c.encodeIfPresent(lowStock, forKey: .lowStock)
        try c.encodeIfPresent(parStock, forKey: .parStock)
        try c.encodeIfPresent(costPerUnit, forKey: .costPerUnit)
        try c.encodeIfPresent(value, forKey: .value)
        try c.encodeIfPresent(prepared, forKey: .prepared)
        try c.encodeIfPresent(byStore, forKey: .byStore)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

public struct StockStore: Noosh24Model {
    public let id: String?
    public let name: String?
    public let isDefault: Bool?
    public let stations: [String]?
    public let raw: JSONValue?

    public init(id: String? = nil, name: String? = nil, isDefault: Bool? = nil, stations: [String]? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.stations = stations
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, name, isDefault, stations
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        name = c.lenient(String.self, forKey: .name)
        isDefault = c.lenient(Bool.self, forKey: .isDefault)
        stations = c.lenientList(String.self, forKey: .stations)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(isDefault, forKey: .isDefault)
        try c.encodeIfPresent(stations, forKey: .stations)
    }
}

public struct StockMove: Noosh24Model {
    public let id: String?
    public let ingredientId: String?
    public let qty: Double?
    public let reason: String?
    public let orderId: String?
    public let invoiceId: String?
    public let storeId: String?
    public let note: String?
    public let createdAt: Date?
    public let raw: JSONValue?

    public init(id: String? = nil, ingredientId: String? = nil, qty: Double? = nil, reason: String? = nil, orderId: String? = nil, invoiceId: String? = nil, storeId: String? = nil, note: String? = nil, createdAt: Date? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.ingredientId = ingredientId
        self.qty = qty
        self.reason = reason
        self.orderId = orderId
        self.invoiceId = invoiceId
        self.storeId = storeId
        self.note = note
        self.createdAt = createdAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, ingredientId, qty, reason, orderId, invoiceId, storeId, note, createdAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        ingredientId = c.lenient(String.self, forKey: .ingredientId)
        qty = c.lenient(Double.self, forKey: .qty)
        reason = c.lenient(String.self, forKey: .reason)
        orderId = c.lenient(String.self, forKey: .orderId)
        invoiceId = c.lenient(String.self, forKey: .invoiceId)
        storeId = c.lenient(String.self, forKey: .storeId)
        note = c.lenient(String.self, forKey: .note)
        createdAt = c.lenientDate(forKey: .createdAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(ingredientId, forKey: .ingredientId)
        try c.encodeIfPresent(qty, forKey: .qty)
        try c.encodeIfPresent(reason, forKey: .reason)
        try c.encodeIfPresent(orderId, forKey: .orderId)
        try c.encodeIfPresent(invoiceId, forKey: .invoiceId)
        try c.encodeIfPresent(storeId, forKey: .storeId)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

public struct ReviewRatings: Noosh24Model {
    public let food: Double?
    public let service: Double?
    public let atmosphere: Double?
    public let cleanliness: Double?
    public let price: Double?
    public let raw: JSONValue?

    public init(food: Double? = nil, service: Double? = nil, atmosphere: Double? = nil, cleanliness: Double? = nil, price: Double? = nil, raw: JSONValue? = nil) {
        self.food = food
        self.service = service
        self.atmosphere = atmosphere
        self.cleanliness = cleanliness
        self.price = price
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case food, service, atmosphere, cleanliness, price
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        food = c.lenient(Double.self, forKey: .food)
        service = c.lenient(Double.self, forKey: .service)
        atmosphere = c.lenient(Double.self, forKey: .atmosphere)
        cleanliness = c.lenient(Double.self, forKey: .cleanliness)
        price = c.lenient(Double.self, forKey: .price)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(food, forKey: .food)
        try c.encodeIfPresent(service, forKey: .service)
        try c.encodeIfPresent(atmosphere, forKey: .atmosphere)
        try c.encodeIfPresent(cleanliness, forKey: .cleanliness)
        try c.encodeIfPresent(price, forKey: .price)
    }
}

public struct Review: Noosh24Model {
    public let id: String?
    public let author: String?
    public let overall: Double?
    public let ratings: ReviewRatings?
    public let body: String?
    public let visitType: String?
    public let visitedOn: Date?
    public let verified: Bool?
    public let reply: String?
    public let repliedAt: Date?
    public let createdAt: Date?
    public let raw: JSONValue?

    public init(id: String? = nil, author: String? = nil, overall: Double? = nil, ratings: ReviewRatings? = nil, body: String? = nil, visitType: String? = nil, visitedOn: Date? = nil, verified: Bool? = nil, reply: String? = nil, repliedAt: Date? = nil, createdAt: Date? = nil, raw: JSONValue? = nil) {
        self.id = id
        self.author = author
        self.overall = overall
        self.ratings = ratings
        self.body = body
        self.visitType = visitType
        self.visitedOn = visitedOn
        self.verified = verified
        self.reply = reply
        self.repliedAt = repliedAt
        self.createdAt = createdAt
        self.raw = raw
    }

    enum CodingKeys: String, CodingKey {
        case id, author, overall, ratings, body, visitType, visitedOn, verified, reply, repliedAt, createdAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(String.self, forKey: .id)
        author = c.lenient(String.self, forKey: .author)
        overall = c.lenient(Double.self, forKey: .overall)
        ratings = c.lenient(ReviewRatings.self, forKey: .ratings)
        body = c.lenient(String.self, forKey: .body)
        visitType = c.lenient(String.self, forKey: .visitType)
        visitedOn = c.lenientDate(forKey: .visitedOn)
        verified = c.lenient(Bool.self, forKey: .verified)
        reply = c.lenient(String.self, forKey: .reply)
        repliedAt = c.lenientDate(forKey: .repliedAt)
        createdAt = c.lenientDate(forKey: .createdAt)
        raw = try? JSONValue(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(author, forKey: .author)
        try c.encodeIfPresent(overall, forKey: .overall)
        try c.encodeIfPresent(ratings, forKey: .ratings)
        try c.encodeIfPresent(body, forKey: .body)
        try c.encodeIfPresent(visitType, forKey: .visitType)
        try c.encodeIfPresent(visitedOn, forKey: .visitedOn)
        try c.encodeIfPresent(verified, forKey: .verified)
        try c.encodeIfPresent(reply, forKey: .reply)
        try c.encodeIfPresent(repliedAt, forKey: .repliedAt)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

public typealias ZReport = [String: JSONValue]
