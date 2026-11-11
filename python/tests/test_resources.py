from __future__ import annotations

from datetime import UTC, date, datetime

import pytest

from noosh24 import PreOrderLine, Product, ServerError, TableTakenError, where

from .conftest import body, page, query

PRODUCT = {
    "id": "0b6f3c1e",
    "name": "Plov",
    "category": "Main",
    "description": "Saffron rice with lamb",
    "price": 14,
    "available": True,
    "popular": True,
    "position": 3,
    "prepMinutes": 20,
    "station": "",
    "vatRate": None,
    "vegetarian": False,
    "spicy": False,
    "allergens": ["gluten"],
    "discountable": True,
    "hasModifiers": True,
    "image": "https://api.noosh24.com/m/5c1d.jpg",
    "video": None,
    "modifierGroups": [
        {
            "id": "g1",
            "name": "Size",
            "required": True,
            "position": 0,
            "modifiers": [
                {"id": "m1", "name": "Large", "priceDelta": 2.5, "position": 0},
            ],
        }
    ],
    "translations": {"en": {"name": "Pilaf", "description": "Rice"}, "ru": {"name": "Плов"}},
}

RESERVATION = {
    "id": "res1",
    "code": "K7Q2",
    "status": "pending",
    "source": "open_api",
    "startsAt": "2026-11-20T15:30:00Z",
    "endsAt": "2026-11-20T17:30:00.123456789Z",
    "guests": 4,
    "zone": "Terrace",
    "table": {"id": "t5", "label": "T5"},
    "guest": {"name": "Aysel", "phone": "+994501234567", "email": None},
    "specialRequest": None,
    "allergyNote": None,
    "birthday": False,
    "childChair": True,
    "depositPaid": 0,
    "preOrder": [{"productId": "p1", "name": "Plov", "price": 14.5, "qty": 2, "note": None}],
    "externalRef": "acme-991",
    "decidedAt": None,
    "createdAt": "2026-11-11T10:00:00.5Z",
    "updatedAt": "2026-11-11T10:00:00Z",
}

BOOKING = dict(date="2026-11-20", time="19:30", guests=4, guest_name="Aysel Məmmədova", phone="+994501234567")


def test_list_products_sends_list_parameters_and_parses_the_page(client, http):
    http.json(200, page([PRODUCT], 87, 50, 50))

    result = client.menu.list_products(
        limit=50,
        offset=50,
        sort=["category asc", "price desc"],
        where=where().eq("category", "Chef's").gte("price", 5).eq("available", True),
        expand=["modifierGroups", "translations"],
    )

    assert http.last.url.path == "/v1/menu/products"
    assert query(http.last) == {
        "limit": ["50"],
        "offset": ["50"],
        "sort": ["category asc", "price desc"],
        "where": ["category = 'Chef''s' AND price >= 5 AND available = true"],
        "expand": ["modifierGroups", "translations"],
    }
    assert (result.total, result.limit, result.offset, result.has_more, len(result)) == (87, 50, 50, True, 1)
    product = result.items[0]
    assert isinstance(product, Product)
    assert product.price == 14.0 and isinstance(product.price, float)
    assert product.vat_rate is None
    assert product.prep_minutes == 20
    assert product.allergens == ["gluten"]
    assert product.modifier_groups[0].modifiers[0].price_delta == 2.5
    assert product.translations["en"].name == "Pilaf"
    assert product.translations["ru"].description is None
    assert product.raw == PRODUCT


def test_list_accepts_plain_where_and_sort_string(client, http):
    http.json(200, page([], 0))

    client.orders.list(where="status = 'served'", sort="createdAt desc")

    assert query(http.last) == {"sort": ["createdAt desc"], "where": ["status = 'served'"]}


def test_unknown_list_parameter_is_rejected(client):
    with pytest.raises(TypeError):
        client.reviews.list(page=2)


def test_iterator_walks_every_page(client, http):
    http.json(200, page([{"id": "c1"}, {"id": "c2"}], 5, 2, 0))
    http.json(200, page([{"id": "c3"}, {"id": "c4"}], 5, 2, 2))
    http.json(200, page([{"id": "c5"}], 5, 2, 4))

    ids = [c.id for c in client.customers.iterate(limit=2, where="createdAt >= '2026-11-01'")]

    assert ids == ["c1", "c2", "c3", "c4", "c5"]
    assert [query(r)["offset"][0] for r in http.requests] == ["0", "2", "4"]
    assert query(http.requests[2])["where"] == ["createdAt >= '2026-11-01'"]


def test_iterator_is_lazy(client, http):
    iterator = client.payments.iterate()
    assert http.requests == []
    http.json(200, page([], 10, 100, 0))
    assert list(iterator) == []
    assert len(http.requests) == 1


def test_iterator_uses_the_largest_page_each_endpoint_allows(client, http):
    for _ in range(3):
        http.json(200, page([], 0))

    list(client.orders.iterate_bills())
    list(client.menu.iterate_products(expand="modifierGroups"))
    list(client.stock.iterate_moves())

    assert [query(r)["limit"][0] for r in http.requests] == ["50", "50", "100"]


def test_get_product_encodes_the_id_and_expand(client, http):
    http.json(200, {"data": PRODUCT})

    product = client.menu.get_product("a/b c", expand="translations")

    assert str(http.last.url) == "https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations"
    assert product.name == "Plov"


def test_empty_id_is_rejected(client):
    with pytest.raises(ValueError):
        client.orders.get("")


def test_categories_and_stop_list(client, http):
    http.json(200, {"data": {"items": [{"name": "Salads", "position": 1, "products": 9, "available": 8}], "total": 1}})
    http.json(200, {"data": {"items": [{"id": "p9", "name": "Dolma", "category": "Main", "price": 9.5}], "total": 1}})

    assert client.menu.list_categories()[0].available == 8
    assert client.menu.get_stop_list()[0].name == "Dolma"
    assert http.last.url.path == "/v1/menu/stop-list"


def test_reservation_parses_nested_fields_and_times(client, http):
    http.json(200, {"data": RESERVATION})

    reservation = client.reservations.get("res1")

    assert reservation.starts_at == datetime(2026, 11, 20, 15, 30, tzinfo=UTC)
    assert reservation.ends_at == datetime(2026, 11, 20, 17, 30, 0, 123456, tzinfo=UTC)
    assert reservation.created_at == datetime(2026, 11, 11, 10, 0, 0, 500000, tzinfo=UTC)
    assert reservation.decided_at is None
    assert reservation.table.label == "T5"
    assert reservation.guest.phone == "+994501234567"
    assert reservation.guest.email is None
    assert reservation.pre_order[0].qty == 2
    assert reservation.deposit_paid == 0.0


def test_availability(client, http):
    http.json(
        200,
        {
            "data": {
                "startsAt": "2026-11-20T15:30:00Z",
                "endsAt": "2026-11-20T17:30:00Z",
                "durationMinutes": 120,
                "openTime": "10:00",
                "closeTime": "23:00",
                "tables": [{"id": "t5", "label": "T5", "hallId": "h1", "zone": "Terrace", "seats": 4, "free": True}],
            }
        },
    )

    result = client.reservations.availability(date(2026, 11, 20), "19:30", guests=4)

    assert query(http.last) == {"date": ["2026-11-20"], "time": ["19:30"], "guests": ["4"]}
    assert result.duration_minutes == 120
    assert result.tables[0].free is True


def test_create_reservation_posts_json_and_reports_created(client, http):
    http.json(201, {"data": RESERVATION})

    result = client.reservations.create(
        date=date(2026, 11, 20),
        time="19:30",
        guests=4,
        guest_name="Aysel Məmmədova",
        phone="+994501234567",
        child_chair=True,
        pre_order=[PreOrderLine(item_id="p1", qty=2), {"item_id": "p2", "qty": 1, "note": "no onion"}],
        external_ref="acme-991",
    )

    request = http.last
    assert request.method == "POST"
    assert str(request.url) == "https://open-api.noosh24.com/v1/reservations"
    assert request.headers["content-type"] == "application/json"
    assert body(request) == {
        "date": "2026-11-20",
        "time": "19:30",
        "guests": 4,
        "guestName": "Aysel Məmmədova",
        "phone": "+994501234567",
        "childChair": True,
        "externalRef": "acme-991",
        "preOrder": [{"itemId": "p1", "qty": 2}, {"itemId": "p2", "qty": 1, "note": "no onion"}],
    }
    assert "Məmmədova".encode() in request.content
    assert result.created is True
    assert result.reservation.code == "K7Q2"


def test_create_with_known_external_ref_returns_the_existing_booking(client, http):
    http.json(200, {"data": RESERVATION})

    result = client.reservations.create(**BOOKING, external_ref="acme-991")

    assert result.created is False
    assert result.reservation.id == "res1"


def test_create_with_external_ref_is_retried(client, http):
    http.json(503, {"error": "temporarily_unavailable"}, {"Retry-After": "0"})
    http.json(201, {"data": RESERVATION})

    result = client.reservations.create(**BOOKING, external_ref="acme-991")

    assert result.created is True
    assert len(http.requests) == 2
    assert http.requests[0].content == http.requests[1].content


def test_create_without_external_ref_is_never_retried(client, http):
    http.json(503, {"error": "temporarily_unavailable"}, {"Retry-After": "0"})

    with pytest.raises(ServerError):
        client.reservations.create(**BOOKING)
    assert len(http.requests) == 1


def test_table_taken(client, http):
    http.json(409, {"error": "table_taken", "message": "Bu masa seçilən vaxt üçün artıq tutulub"})

    with pytest.raises(TableTakenError, match="artıq tutulub"):
        client.reservations.create(**BOOKING, table_id="t5", external_ref="x")


def test_cancel(client, http):
    http.json(200, {"data": dict(RESERVATION, status="cancelled")})

    reservation = client.reservations.cancel("res1")

    assert http.last.method == "POST"
    assert str(http.last.url) == "https://open-api.noosh24.com/v1/reservations/res1/cancel"
    assert http.last.content == b""
    assert reservation.status == "cancelled"


def test_orders_bills_payments_and_z_report(client, http):
    http.json(
        200,
        {
            "data": {
                "id": "o1",
                "number": "A-12",
                "dailyNumber": 12,
                "kind": "delivery",
                "status": "ready",
                "subtotal": 30,
                "items": [{"id": "i1", "productId": "p1", "name": "Plov", "qty": 2, "price": 15, "comp": False}],
                "delivery": {
                    "status": "accepted",
                    "platform": {"id": "wolt", "name": "Wolt", "ref": "W-1"},
                    "fee": 2,
                    "acceptedAt": "2026-11-11T09:00:00Z",
                },
            }
        },
    )
    http.json(200, {"data": {"id": "b1", "status": "paid", "orderIds": ["o1", "o2"], "total": 45.5, "closedAt": None}})
    http.json(
        200,
        {
            "data": {
                "id": "pay1",
                "method": "card",
                "amount": 20,
                "card": {"maskedPan": "4169********1234", "scheme": "visa", "bank": "Kapital"},
                "platform": None,
            }
        },
    )
    http.json(200, {"data": {"date": "2026-11-10", "cash": 120.5}})

    order = client.orders.get("o1")
    bill = client.orders.get_bill("b1")
    payment = client.payments.get("pay1")
    z = client.payments.z_report("2026-11-10")

    assert order.delivery.platform.name == "Wolt"
    assert order.delivery.fee == 2.0
    assert order.items[0].price == 15.0
    assert bill.order_ids == ["o1", "o2"]
    assert bill.closed_at is None
    assert payment.card.masked_pan == "4169********1234"
    assert payment.platform is None
    assert z["cash"] == 120.5
    assert query(http.last) == {"date": ["2026-11-10"]}
    assert [r.url.path for r in http.requests] == ["/v1/orders/o1", "/v1/bills/b1", "/v1/payments/pay1", "/v1/reports/z"]


def test_tables_loyalty_stock_and_reviews(client, http):
    http.json(200, {"data": {"items": [{"id": "t1", "label": "T1", "status": "occupied", "billTotal": 42.1}], "total": 1}})
    http.json(200, {"data": {"stampsNeeded": 8, "earnBy": "visit", "rewardProductIds": ["p1"]}})
    http.json(200, page([{"id": "card1", "stamps": 5, "lastVisitAt": None}], 1, 100))
    http.json(200, page([{"id": "ing1", "name": "Rice", "stock": 12, "byStore": {"s1": 10, "s2": 2.5}}], 1))
    http.json(200, {"data": {"items": [{"id": "s1", "name": "Main", "isDefault": True, "stations": ["hot"]}], "total": 1}})
    http.json(200, page([{"id": "rv1", "overall": 4.5, "ratings": {"food": 5, "service": 4}, "reply": None}], 1))

    assert client.tables.list()[0].bill_total == 42.1
    assert client.loyalty.get_program().stamps_needed == 8
    assert client.loyalty.list_cards().has_more is False
    assert client.stock.list_ingredients().items[0].by_store == {"s1": 10.0, "s2": 2.5}
    assert client.stock.list_stores()[0].is_default is True
    review = client.reviews.list().items[0]
    assert review.ratings.food == 5.0
    assert review.ratings.price is None
    assert [r.url.path for r in http.requests] == [
        "/v1/tables",
        "/v1/loyalty/program",
        "/v1/loyalty/cards",
        "/v1/stock/ingredients",
        "/v1/stock/stores",
        "/v1/reviews",
    ]


def test_models_tolerate_missing_and_unknown_fields(client, http):
    http.json(201, {"data": {"id": "res9", "code": "ZZ11", "status": "pending", "brandNew": 1}})

    result = client.reservations.create(**BOOKING)

    assert result.reservation.code == "ZZ11"
    assert result.reservation.guest is None
    assert result.reservation.pre_order == []
    assert result.reservation.raw["brandNew"] == 1
