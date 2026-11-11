import Foundation
import Noosh24
import Testing

let product: JSONValue = [
    "id": "0b6f3c1e",
    "name": "Plov",
    "category": "Main",
    "description": "Saffron rice with lamb",
    "price": 14,
    "available": true,
    "popular": true,
    "position": 3,
    "prepMinutes": 20,
    "station": "",
    "vatRate": nil,
    "vegetarian": false,
    "spicy": false,
    "allergens": ["gluten"],
    "discountable": true,
    "hasModifiers": true,
    "image": "https://api.noosh24.com/m/5c1d.jpg",
    "video": nil,
    "modifierGroups": [
        [
            "id": "g1",
            "name": "Size",
            "required": true,
            "position": 0,
            "modifiers": [["id": "m1", "name": "Large", "priceDelta": 2.5, "position": 0]],
        ]
    ],
    "translations": ["en": ["name": "Pilaf", "description": "Rice"], "ru": ["name": "Плов"]],
]

let reservation: JSONValue = [
    "id": "res1",
    "code": "K7Q2",
    "status": "pending",
    "source": "open_api",
    "startsAt": "2026-11-20T15:30:00Z",
    "endsAt": "2026-11-20T17:30:00.123456789Z",
    "guests": 4,
    "zone": "Terrace",
    "table": ["id": "t5", "label": "T5"],
    "guest": ["name": "Aysel", "phone": "+994501234567", "email": nil],
    "specialRequest": nil,
    "allergyNote": nil,
    "birthday": false,
    "childChair": true,
    "depositPaid": 0,
    "preOrder": [["productId": "p1", "name": "Plov", "price": 14.5, "qty": 2, "note": nil]],
    "externalRef": "acme-991",
    "decidedAt": nil,
    "createdAt": "2026-11-11T10:00:00.5Z",
    "updatedAt": "2026-11-11T10:00:00Z",
]

func booking(externalRef: String? = nil, tableId: String? = nil) -> NewReservation {
    NewReservation(
        date: "2026-11-20", time: "19:30", guests: 4, guestName: "Aysel Məmmədova", phone: "+994501234567",
        tableId: tableId, externalRef: externalRef)
}

func with(_ value: JSONValue, _ key: String, _ replacement: JSONValue) -> JSONValue {
    guard case .object(var object) = value else { return value }
    object[key] = replacement
    return .object(object)
}

@Suite struct ResourceTests {
    @Test func listProductsSendsListParametersAndParsesThePage() async throws {
        let h = try Harness()
        await h.http.json(200, page([product], 87, 50, 50))

        let result = try await h.client.menu.listProducts(
            limit: 50,
            offset: 50,
            sort: ["category asc", "price desc"],
            where: try Where().eq("category", "Chef's").gte("price", 5).eq("available", true),
            expand: [.modifierGroups, .translations]
        )

        let request = await h.http.last
        #expect(path(request) == "/v1/menu/products")
        #expect(query(request) == [
            "limit": ["50"],
            "offset": ["50"],
            "sort": ["category asc", "price desc"],
            "where": ["category = 'Chef''s' AND price >= 5 AND available = true"],
            "expand": ["modifierGroups", "translations"],
        ])
        #expect(request.url.query?.contains("where=category%20%3D%20%27Chef%27%27s%27%20AND") == true)
        #expect(result.total == 87)
        #expect(result.limit == 50)
        #expect(result.offset == 50)
        #expect(result.hasMore)
        #expect(result.nextOffset == 51)
        #expect(result.count == 1)
        let item = try #require(result.first)
        #expect(item.price == 14.0)
        #expect(item.vatRate == nil)
        #expect(item.prepMinutes == 20)
        #expect(item.station == "")
        #expect(item.allergens == ["gluten"])
        #expect(item.image == "https://api.noosh24.com/m/5c1d.jpg")
        #expect(item.video == nil)
        #expect(item.modifierGroups?.first?.required == true)
        #expect(item.modifierGroups?.first?.modifiers?.first?.priceDelta == 2.5)
        #expect(item.translations?["en"]?.name == "Pilaf")
        #expect(item.translations?["ru"]?.name == "Плов")
        #expect(item.translations?["ru"]?.description == nil)
        #expect(item.raw == product)
    }

    @Test func listAcceptsPlainWhereAndSortString() async throws {
        let h = try Harness()
        await h.http.json(200, page([], 0))

        let filter = "status = 'served'"
        _ = try await h.client.orders.list(sort: "createdAt desc", where: filter)

        #expect(query(await h.http.last) == ["sort": ["createdAt desc"], "where": ["status = 'served'"]])
    }

    @Test func iteratorWalksEveryPage() async throws {
        let h = try Harness()
        await h.http.json(200, page([["id": "c1"], ["id": "c2"]], 5, 2, 0))
        await h.http.json(200, page([["id": "c3"], ["id": "c4"]], 5, 2, 2))
        await h.http.json(200, page([["id": "c5"]], 5, 2, 4))

        var ids: [String] = []
        for try await customer in h.client.customers.iterate(limit: 2, where: "createdAt >= '2026-11-01'") {
            ids.append(customer.id ?? "")
        }

        let requests = await h.http.requests
        #expect(ids == ["c1", "c2", "c3", "c4", "c5"])
        #expect(requests.map { query($0)["offset"]?.first } == ["0", "2", "4"])
        #expect(requests.map { query($0)["limit"]?.first } == ["2", "2", "2"])
        #expect(query(requests[2])["where"] == ["createdAt >= '2026-11-01'"])
    }

    @Test func iteratorStartsAtTheGivenOffset() async throws {
        let h = try Harness()
        await h.http.json(200, page([["id": "c41"]], 41, 100, 40))

        let customers = try await h.client.customers.iterate(offset: 40).collect()

        #expect(customers.map(\.id) == ["c41"])
        #expect(query(await h.http.last)["offset"] == ["40"])
    }

    @Test func iteratorIsLazy() async throws {
        let h = try Harness()
        let sequence = h.client.payments.iterate()
        #expect(await h.http.requests.isEmpty)

        await h.http.json(200, page([], 10, 100, 0))
        let payments = try await sequence.collect()

        #expect(payments.isEmpty)
        #expect(await h.http.requests.count == 1)
    }

    @Test func iteratorUsesTheLargestPageEachEndpointAllows() async throws {
        let h = try Harness()
        for _ in 0..<4 {
            await h.http.json(200, page([], 0))
        }

        _ = try await h.client.orders.iterateBills().collect()
        _ = try await h.client.menu.iterateProducts(expand: [.modifierGroups]).collect()
        _ = try await h.client.stock.iterateMoves().collect()
        _ = try await h.client.menu.iterateProducts().collect()

        #expect(await h.http.requests.map { query($0)["limit"]?.first } == ["50", "50", "100", "100"])
    }

    @Test func getProductEncodesTheIdAndExpand() async throws {
        let h = try Harness()
        await h.http.json(200, ["data": product])

        let item = try await h.client.menu.getProduct("a/b c", expand: [.translations])

        #expect(await h.http.last.url.absoluteString == "https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations")
        #expect(item.name == "Plov")
    }

    @Test func emptyIdIsRejected() async throws {
        let h = try Harness()
        for id in ["", "   "] {
            let error = await failure { try await h.client.orders.get(id) }
            guard case .invalidArgument? = error as? Noosh24Error else {
                Issue.record("expected invalidArgument, got \(String(describing: error))")
                continue
            }
        }
        #expect(await h.http.requests.isEmpty)
    }

    @Test func categoriesAndStopList() async throws {
        let h = try Harness()
        await h.http.json(200, ["data": ["items": [["name": "Salads", "position": 1, "products": 9, "available": 8]], "total": 1]])
        await h.http.json(200, ["data": ["items": [["id": "p9", "name": "Dolma", "category": "Main", "price": 9.5]], "total": 1]])

        let categories = try await h.client.menu.listCategories()
        let stopList = try await h.client.menu.getStopList()

        #expect(categories.first?.available == 8)
        #expect(categories.first?.products == 9)
        #expect(stopList.first?.name == "Dolma")
        #expect(stopList.first?.price == 9.5)
        #expect(await h.http.requests.map(path) == ["/v1/menu/categories", "/v1/menu/stop-list"])
    }

    @Test func reservationParsesNestedFieldsAndTimes() async throws {
        let h = try Harness()
        await h.http.json(200, ["data": reservation])

        let r = try await h.client.reservations.get("res1")

        #expect(path(await h.http.last) == "/v1/reservations/res1")
        #expect(r.startsAt == utc(1_795_188_600))
        let endsAt = try #require(r.endsAt)
        #expect(abs(endsAt.timeIntervalSince(utc(1_795_195_800)) - 0.123456789) < 0.000001)
        #expect(endsAt > utc(1_795_195_800, 0.123456))
        #expect(r.createdAt == utc(1_794_391_200, 0.5))
        #expect(r.decidedAt == nil)
        #expect(r.status == .pending)
        #expect(r.source == .openApi)
        #expect(r.table?.label == "T5")
        #expect(r.guest?.phone == "+994501234567")
        #expect(r.guest?.email == nil)
        #expect(r.preOrder?.first?.qty == 2)
        #expect(r.preOrder?.first?.price == 14.5)
        #expect(r.depositPaid == 0)
        #expect(r.childChair == true)
        #expect(r.externalRef == "acme-991")
    }

    @Test func availability() async throws {
        let h = try Harness()
        await h.http.json(200, [
            "data": [
                "startsAt": "2026-11-20T15:30:00Z",
                "endsAt": "2026-11-20T17:30:00Z",
                "durationMinutes": 120,
                "openTime": "10:00",
                "closeTime": "23:00",
                "tables": [["id": "t5", "label": "T5", "hallId": "h1", "zone": "Terrace", "seats": 4, "free": true]],
            ],
        ])

        let result = try await h.client.reservations.availability(date: PlainDate(year: 2026, month: 11, day: 20), time: "19:30", guests: 4)

        let request = await h.http.last
        #expect(path(request) == "/v1/reservations/availability")
        #expect(query(request) == ["date": ["2026-11-20"], "time": ["19:30"], "guests": ["4"]])
        #expect(result.durationMinutes == 120)
        #expect(result.endsAt == utc(1_795_195_800))
        #expect(result.tables?.first?.free == true)
        #expect(result.tables?.first?.seats == 4)
    }

    @Test func createReservationPostsJSONAndReportsCreated() async throws {
        let h = try Harness()
        await h.http.json(201, ["data": reservation])

        let result = try await h.client.reservations.create(
            NewReservation(
                date: PlainDate(year: 2026, month: 11, day: 20),
                time: "19:30",
                guests: 4,
                guestName: "Aysel Məmmədova",
                phone: "+994501234567",
                childChair: true,
                preOrder: [PreOrderLine(itemId: "p1", qty: 2), PreOrderLine(itemId: "p2", qty: 1, note: "no onion")],
                externalRef: "acme-991"
            )
        )

        let request = await h.http.last
        #expect(request.method == "POST")
        #expect(request.url.absoluteString == "https://open-api.noosh24.com/v1/reservations")
        #expect(request.headers["Content-Type"] == "application/json")
        #expect(try body(request) == [
            "date": "2026-11-20",
            "time": "19:30",
            "guests": 4,
            "guestName": "Aysel Məmmədova",
            "phone": "+994501234567",
            "childChair": true,
            "externalRef": "acme-991",
            "preOrder": [["itemId": "p1", "qty": 2], ["itemId": "p2", "qty": 1, "note": "no onion"]],
        ])
        let text = String(decoding: request.body ?? Data(), as: UTF8.self)
        #expect(text.contains("Məmmədova"))
        #expect(!text.contains("\\u"))
        #expect(result.created)
        #expect(result.reservation.code == "K7Q2")
    }

    @Test func createWithKnownExternalRefReturnsTheExistingBooking() async throws {
        let h = try Harness()
        await h.http.json(200, ["data": reservation])

        let result = try await h.client.reservations.create(booking(externalRef: "acme-991"))

        #expect(!result.created)
        #expect(result.reservation.id == "res1")
    }

    @Test func createWithExternalRefIsRetried() async throws {
        let h = try Harness()
        await h.http.json(503, ["error": "temporarily_unavailable"], headers: ["Retry-After": "0"])
        await h.http.json(201, ["data": reservation])

        let result = try await h.client.reservations.create(booking(externalRef: "acme-991"))

        let requests = await h.http.requests
        #expect(result.created)
        #expect(requests.count == 2)
        #expect(requests[0].body == requests[1].body)
        #expect(await h.sleeps.calls == [.zero])
    }

    @Test func createWithoutExternalRefIsNeverRetried() async throws {
        let h = try Harness()
        await h.http.json(503, ["error": "temporarily_unavailable"], headers: ["Retry-After": "0"])

        let error = await failure { try await h.client.reservations.create(booking()) }

        #expect(error.flatMap(apiError)?.kind == .server)
        #expect(await h.http.requests.count == 1)
    }

    @Test func createWithBlankExternalRefIsNeverRetried() async throws {
        let h = try Harness()
        await h.http.fail(Boom(description: "connection reset"))

        let error = await failure { try await h.client.reservations.create(booking(externalRef: "  ")) }

        #expect((error as? Noosh24Error)?.isConnectionError == true)
        #expect(await h.http.requests.count == 1)
    }

    @Test func tableTaken() async throws {
        let h = try Harness()
        await h.http.json(409, ["error": "table_taken", "message": "Bu masa seçilən vaxt üçün artıq tutulub"])

        let error = await failure { try await h.client.reservations.create(booking(externalRef: "x", tableId: "t5")) }

        let api = try #require(error.flatMap(apiError))
        #expect(api.code == .tableTaken)
        #expect(api.kind == .conflict)
        #expect(api.message.contains("artıq tutulub"))
        #expect(await h.http.requests.count == 1)
    }

    @Test func cancel() async throws {
        let h = try Harness()
        await h.http.json(200, ["data": with(reservation, "status", "cancelled")])

        let r = try await h.client.reservations.cancel("res1")

        let request = await h.http.last
        #expect(request.method == "POST")
        #expect(request.url.absoluteString == "https://open-api.noosh24.com/v1/reservations/res1/cancel")
        #expect(request.body == nil)
        #expect(request.headers["Content-Type"] == nil)
        #expect(r.status == .cancelled)
    }

    @Test func ordersBillsPaymentsAndZReport() async throws {
        let h = try Harness()
        await h.http.json(200, [
            "data": [
                "id": "o1",
                "number": "A-12",
                "dailyNumber": 12,
                "kind": "delivery",
                "status": "ready",
                "subtotal": 30,
                "items": [["id": "i1", "productId": "p1", "name": "Plov", "qty": 2, "price": 15, "comp": false]],
                "delivery": [
                    "status": "accepted",
                    "platform": ["id": "wolt", "name": "Wolt", "ref": "W-1"],
                    "fee": 2,
                    "acceptedAt": "2026-11-11T09:00:00Z",
                ],
            ],
        ])
        await h.http.json(200, ["data": ["id": "b1", "status": "paid", "orderIds": ["o1", "o2"], "total": 45.5, "closedAt": nil]])
        await h.http.json(200, [
            "data": [
                "id": "pay1",
                "method": "card",
                "amount": 20,
                "card": ["maskedPan": "4169********1234", "scheme": "visa", "bank": "Kapital"],
                "platform": nil,
            ],
        ])
        await h.http.json(200, ["data": ["date": "2026-11-10", "cash": 120.5]])

        let order = try await h.client.orders.get("o1")
        let bill = try await h.client.orders.getBill("b1")
        let payment = try await h.client.payments.get("pay1")
        let z = try await h.client.payments.zReport(date: "2026-11-10")

        #expect(order.kind == .delivery)
        #expect(order.status == .ready)
        #expect(order.dailyNumber == 12)
        #expect(order.delivery?.platform?.name == "Wolt")
        #expect(order.delivery?.fee == 2.0)
        #expect(order.delivery?.acceptedAt == utc(1_794_387_600))
        #expect(order.items?.first?.price == 15.0)
        #expect(bill.status == .paid)
        #expect(bill.orderIds == ["o1", "o2"])
        #expect(bill.total == 45.5)
        #expect(bill.closedAt == nil)
        #expect(payment.method == .card)
        #expect(payment.card?.maskedPan == "4169********1234")
        #expect(payment.platform == nil)
        #expect(z["cash"] == .number(120.5))
        #expect(z["date"]?.stringValue == "2026-11-10")
        let requests = await h.http.requests
        #expect(query(requests[3]) == ["date": ["2026-11-10"]])
        #expect(requests.map(path) == ["/v1/orders/o1", "/v1/bills/b1", "/v1/payments/pay1", "/v1/reports/z"])
    }

    @Test func zReportWithoutDate() async throws {
        let h = try Harness()
        await h.http.json(200, ["data": ["total": 10]])

        let z = try await h.client.payments.zReport()

        #expect(z["total"]?.intValue == 10)
        #expect(await h.http.last.url.query == nil)
    }

    @Test func tablesLoyaltyStockAndReviews() async throws {
        let h = try Harness()
        await h.http.json(200, ["data": ["items": [["id": "t1", "label": "T1", "status": "occupied", "billTotal": 42.1]], "total": 1]])
        await h.http.json(200, ["data": ["stampsNeeded": 8, "earnBy": "visit", "rewardProductIds": ["p1"]]])
        await h.http.json(200, page([["id": "card1", "stamps": 5, "lastVisitAt": nil]], 1, 100))
        await h.http.json(200, page([["id": "ing1", "name": "Rice", "stock": 12, "byStore": ["s1": 10, "s2": 2.5]]], 1))
        await h.http.json(200, ["data": ["items": [["id": "s1", "name": "Main", "isDefault": true, "stations": ["hot"]]], "total": 1]])
        await h.http.json(200, page([["id": "rv1", "overall": 4.5, "ratings": ["food": 5, "service": 4], "reply": nil]], 1))
        await h.http.json(200, page([], 0))

        let table = try await h.client.tables.list().first
        #expect(table?.billTotal == 42.1)
        #expect(table?.status == .occupied)
        let program = try await h.client.loyalty.getProgram()
        #expect(program.stampsNeeded == 8)
        #expect(program.earnBy == .visit)
        #expect(program.rewardProductIds == ["p1"])
        let cards = try await h.client.loyalty.listCards()
        #expect(!cards.hasMore)
        #expect(cards.first?.lastVisitAt == nil)
        let ingredients = try await h.client.stock.listIngredients()
        #expect(ingredients.first?.byStore == ["s1": 10.0, "s2": 2.5])
        let stores = try await h.client.stock.listStores()
        #expect(stores.first?.isDefault == true)
        let review = try #require(try await h.client.reviews.list().first)
        #expect(review.ratings?.food == 5.0)
        #expect(review.ratings?.price == nil)
        _ = try await h.client.stock.listMoves()
        #expect(await h.http.requests.map(path) == [
            "/v1/tables",
            "/v1/loyalty/program",
            "/v1/loyalty/cards",
            "/v1/stock/ingredients",
            "/v1/stock/stores",
            "/v1/reviews",
            "/v1/stock/moves",
        ])
    }

    @Test func modelsTolerateMissingAndUnknownFields() async throws {
        let h = try Harness()
        await h.http.json(201, ["data": ["id": "res9", "code": "ZZ11", "status": "pending", "brandNew": 1]])

        let result = try await h.client.reservations.create(booking())

        #expect(result.created)
        #expect(result.reservation.code == "ZZ11")
        #expect(result.reservation.guest == nil)
        #expect(result.reservation.preOrder == nil)
        #expect(result.reservation.startsAt == nil)
        #expect(result.reservation.raw?["brandNew"] == 1)
    }

    @Test func modelsTolerateWrongTypesAndUnknownEnumValues() async throws {
        let h = try Harness()
        await h.http.json(200, [
            "data": [
                "id": "res2",
                "status": "seated_at_bar",
                "guests": "four",
                "startsAt": "not a time",
                "endsAt": "2026-11-20T21:30:00+04:00",
                "table": "T5",
                "preOrder": [["name": "Plov"], "junk", 3],
            ],
        ])

        let r = try await h.client.reservations.get("res2")

        #expect(r.status == .unknown("seated_at_bar"))
        #expect(r.status?.rawValue == "seated_at_bar")
        #expect(r.guests == nil)
        #expect(r.startsAt == nil)
        #expect(r.endsAt == utc(1_795_195_800))
        #expect(r.table == nil)
        #expect(r.preOrder?.map(\.name) == ["Plov"])
    }

    @Test func dataThatIsNotAnObjectGivesAnEmptyModel() async throws {
        let h = try Harness()
        await h.http.json(200, ["data": nil])

        let r = try await h.client.reservations.get("res3")

        #expect(r.id == nil)
    }

    @Test func modelsRoundTripThroughCodable() throws {
        let original = Reservation(id: "r1", status: .checkedIn, guests: 2, table: ReservationTable(id: "t1", label: "T1"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Reservation.self, from: data)
        #expect(decoded.id == "r1")
        #expect(decoded.status == .checkedIn)
        #expect(try JSONDecoder().decode(JSONValue.self, from: data)["status"] == "checked_in")
        #expect(decoded.table == ReservationTable(id: "t1", label: "T1", raw: ["id": "t1", "label": "T1"]))
    }

    @Test func noosh24DateStrategy() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .noosh24
        let dates = try decoder.decode([Date].self, from: Data(#"["2026-11-20T15:30:00Z","2026-11-20T19:30:00.5+04:00","2026-11-20T15:30:00.123456789123Z"]"#.utf8))
        #expect(dates[0] == utc(1_795_188_600))
        #expect(dates[1] == utc(1_795_188_600, 0.5))
        #expect(abs(dates[2].timeIntervalSince(utc(1_795_188_600)) - 0.123456789) < 0.000001)
        #expect(throws: DecodingError.self) {
            try decoder.decode([Date].self, from: Data(#"["2026-13-01T00:00:00Z"]"#.utf8))
        }
    }
}
