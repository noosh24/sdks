mod common;

use chrono::{NaiveDate, NaiveTime, TimeZone, Utc};
use common::{body, expect_query, page, path, query, setup};
use futures::{StreamExt, TryStreamExt};
use noosh24::{
    Error, ListParams, NewReservation, PaymentMethod, PreOrderLine, Product, ReservationSource, ReservationStatus,
    Where,
};
use serde_json::{Value, json};

fn product() -> Value {
    json!({
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
        "vatRate": null,
        "vegetarian": false,
        "spicy": false,
        "allergens": ["gluten"],
        "discountable": true,
        "hasModifiers": true,
        "image": "https://api.noosh24.com/m/5c1d.jpg",
        "video": null,
        "modifierGroups": [{
            "id": "g1",
            "name": "Size",
            "required": true,
            "position": 0,
            "modifiers": [{"id": "m1", "name": "Large", "priceDelta": 2.5, "position": 0}]
        }],
        "translations": {"en": {"name": "Pilaf", "description": "Rice"}, "ru": {"name": "Плов"}}
    })
}

fn reservation() -> Value {
    json!({
        "id": "res1",
        "code": "K7Q2",
        "status": "pending",
        "source": "open_api",
        "startsAt": "2026-11-20T15:30:00Z",
        "endsAt": "2026-11-20T17:30:00.123456789Z",
        "guests": 4,
        "zone": "Terrace",
        "table": {"id": "t5", "label": "T5"},
        "guest": {"name": "Aysel", "phone": "+994501234567", "email": null},
        "specialRequest": null,
        "allergyNote": null,
        "birthday": false,
        "childChair": true,
        "depositPaid": 0,
        "preOrder": [{"productId": "p1", "name": "Plov", "price": 14.5, "qty": 2, "note": null}],
        "externalRef": "acme-991",
        "decidedAt": null,
        "createdAt": "2026-11-11T10:00:00.5Z",
        "updatedAt": "2026-11-11T10:00:00Z"
    })
}

fn date(y: i32, m: u32, d: u32) -> NaiveDate {
    NaiveDate::from_ymd_opt(y, m, d).unwrap()
}

fn booking() -> NewReservation {
    NewReservation::new(
        date(2026, 11, 20),
        NaiveTime::from_hms_opt(19, 30, 0).unwrap(),
        4,
        "Aysel Məmmədova",
        "+994501234567",
    )
}

#[tokio::test]
async fn list_products_sends_list_parameters_and_parses_the_page() {
    let t = setup();
    t.http.json(200, page(json!([product()]), 87, 50, 50));

    let result = t
        .client
        .menu()
        .list_products(ListParams {
            limit: Some(50),
            offset: Some(50),
            sort: vec!["category asc".into(), "price desc".into()],
            where_: Some(
                Where::new()
                    .eq("category", "Chef's")
                    .gte("price", 5)
                    .eq("available", true)
                    .into(),
            ),
            expand: vec!["modifierGroups".into(), "translations".into()],
        })
        .await
        .unwrap();

    let request = t.http.last();
    assert_eq!(path(&request), "/v1/menu/products");
    assert_eq!(
        query(&request),
        expect_query(&[
            ("limit", &["50"]),
            ("offset", &["50"]),
            ("sort", &["category asc", "price desc"]),
            ("where", &["category = 'Chef''s' AND price >= 5 AND available = true"]),
            ("expand", &["modifierGroups", "translations"]),
        ])
    );
    assert!(!request.url.contains('+'));
    assert!(request.url.contains("category%20asc"));
    assert_eq!(
        (
            result.total,
            result.limit,
            result.offset,
            result.has_more(),
            result.len()
        ),
        (87, 50, 50, true, 1)
    );
    assert_eq!(result.next_offset(), 51);
    let product: &Product = &result.items[0];
    assert_eq!(product.price, Some(14.0));
    assert_eq!(product.vat_rate, None);
    assert_eq!(product.prep_minutes, Some(20));
    assert_eq!(product.allergens, vec!["gluten"]);
    assert_eq!(product.modifier_groups[0].modifiers[0].price_delta, Some(2.5));
    assert_eq!(product.translations["en"].name.as_deref(), Some("Pilaf"));
    assert_eq!(product.translations["ru"].description, None);
    assert!(product.extra.is_empty());
}

#[tokio::test]
async fn list_accepts_plain_where_and_sort_string() {
    let t = setup();
    t.http.json(200, page(json!([]), 0, 20, 0));

    t.client
        .orders()
        .list(ListParams::new().where_("status = 'served'").sort("createdAt desc"))
        .await
        .unwrap();

    assert_eq!(
        query(&t.http.last()),
        expect_query(&[("sort", &["createdAt desc"]), ("where", &["status = 'served'"])])
    );
}

#[tokio::test]
async fn invalid_where_and_expand_fail_before_any_request() {
    let t = setup();

    let bad_where = t
        .client
        .reviews()
        .list(ListParams::new().where_(Where::new().eq("bad field", 1)))
        .await
        .unwrap_err();
    let bad_expand = t
        .client
        .orders()
        .list(ListParams::new().expand("translations"))
        .await
        .unwrap_err();
    let mut stream = t
        .client
        .customers()
        .iterate(ListParams::new().where_(Where::new().in_("id", Vec::<&str>::new())));
    let streamed = stream.next().await.unwrap().unwrap_err();

    assert!(matches!(bad_where, Error::InvalidArgument(_)));
    assert!(matches!(bad_expand, Error::InvalidArgument(_)));
    assert!(streamed.is_invalid_argument());
    assert!(stream.next().await.is_none());
    assert_eq!(t.http.count(), 0);
}

#[tokio::test]
async fn iterator_walks_every_page() {
    let t = setup();
    t.http.json(200, page(json!([{"id": "c1"}, {"id": "c2"}]), 5, 2, 0));
    t.http.json(200, page(json!([{"id": "c3"}, {"id": "c4"}]), 5, 2, 2));
    t.http.json(200, page(json!([{"id": "c5"}]), 5, 2, 4));

    let customers: Vec<_> = t
        .client
        .customers()
        .iterate(ListParams::new().limit(2).where_("createdAt >= '2026-11-01'"))
        .try_collect()
        .await
        .unwrap();

    let ids: Vec<_> = customers.iter().map(|c| c.id.clone().unwrap()).collect();
    assert_eq!(ids, vec!["c1", "c2", "c3", "c4", "c5"]);
    let requests = t.http.requests();
    let offsets: Vec<_> = requests.iter().map(|r| query(r)["offset"][0].clone()).collect();
    assert_eq!(offsets, vec!["0", "2", "4"]);
    assert_eq!(query(&requests[2])["where"], vec!["createdAt >= '2026-11-01'"]);
    assert_eq!(query(&requests[2])["limit"], vec!["2"]);
}

#[tokio::test]
async fn iterator_starts_at_the_given_offset_and_stops_on_error() {
    let t = setup();
    t.http.json(200, page(json!([{"id": "r1"}]), 3, 1, 1));
    t.http.json(404, json!({"error": "not_found"}));

    let results: Vec<_> = t
        .client
        .reviews()
        .iterate(ListParams::new().limit(1).offset(1))
        .collect()
        .await;

    assert_eq!(results.len(), 2);
    assert!(results[0].is_ok());
    assert!(results[1].as_ref().unwrap_err().is_not_found());
    assert_eq!(query(&t.http.requests()[0])["offset"], vec!["1"]);
}

#[tokio::test]
async fn iterator_is_lazy() {
    let t = setup();
    let stream = t.client.payments().iterate(ListParams::default());
    assert_eq!(t.http.count(), 0);
    t.http.json(200, page(json!([]), 10, 100, 0));

    let payments: Vec<_> = stream.try_collect().await.unwrap();

    assert!(payments.is_empty());
    assert_eq!(t.http.count(), 1);
}

#[tokio::test]
async fn iterator_uses_the_largest_page_each_endpoint_allows() {
    let t = setup();
    for _ in 0..7 {
        t.http.json(200, page(json!([]), 0, 20, 0));
    }

    let _: Vec<_> = t.client.orders().iterate_bills(ListParams::new()).collect().await;
    let _: Vec<_> = t
        .client
        .menu()
        .iterate_products(ListParams::new().expand("modifierGroups"))
        .collect()
        .await;
    let _: Vec<_> = t.client.stock().iterate_moves(ListParams::new()).collect().await;
    let _: Vec<_> = t.client.menu().iterate_products(ListParams::new()).collect().await;
    let _: Vec<_> = t.client.orders().iterate(ListParams::new()).collect().await;
    let _: Vec<_> = t.client.stock().iterate_ingredients(ListParams::new()).collect().await;
    let _: Vec<_> = t.client.loyalty().iterate_cards(ListParams::new()).collect().await;

    let limits: Vec<_> = t.http.requests().iter().map(|r| query(r)["limit"][0].clone()).collect();
    assert_eq!(limits, vec!["50", "50", "100", "100", "100", "100", "100"]);
    let paths: Vec<_> = t.http.requests().iter().map(path).collect();
    assert_eq!(
        paths,
        vec![
            "/v1/bills",
            "/v1/menu/products",
            "/v1/stock/moves",
            "/v1/menu/products",
            "/v1/orders",
            "/v1/stock/ingredients",
            "/v1/loyalty/cards"
        ]
    );
}

#[tokio::test]
async fn get_product_encodes_the_id_and_expand() {
    let t = setup();
    t.http.json(200, json!({"data": product()}));

    let product = t.client.menu().get_product("a/b c", &["translations"]).await.unwrap();

    assert_eq!(
        t.http.last().url,
        "https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations"
    );
    assert_eq!(product.name.as_deref(), Some("Plov"));
}

#[tokio::test]
async fn empty_id_is_rejected() {
    let t = setup();

    assert!(t.client.orders().get("").await.unwrap_err().is_invalid_argument());
    assert!(
        t.client
            .reservations()
            .cancel("  ")
            .await
            .unwrap_err()
            .is_invalid_argument()
    );
    assert!(
        t.client
            .menu()
            .get_product("", &[])
            .await
            .unwrap_err()
            .is_invalid_argument()
    );
    assert_eq!(t.http.count(), 0);
}

#[tokio::test]
async fn categories_and_stop_list() {
    let t = setup();
    t.http.json(
        200,
        json!({"data": {"items": [{"name": "Salads", "position": 1, "products": 9, "available": 8}], "total": 1}}),
    );
    t.http.json(
        200,
        json!({"data": {"items": [{"id": "p9", "name": "Dolma", "category": "Main", "price": 9.5}], "total": 1}}),
    );

    assert_eq!(t.client.menu().list_categories().await.unwrap()[0].available, Some(8));
    assert_eq!(
        t.client.menu().get_stop_list().await.unwrap()[0].name.as_deref(),
        Some("Dolma")
    );
    let paths: Vec<_> = t.http.requests().iter().map(path).collect();
    assert_eq!(paths, vec!["/v1/menu/categories", "/v1/menu/stop-list"]);
}

#[tokio::test]
async fn reservation_parses_nested_fields_and_times() {
    let t = setup();
    t.http.json(200, json!({"data": reservation()}));

    let reservation = t.client.reservations().get("res1").await.unwrap();

    assert_eq!(path(&t.http.last()), "/v1/reservations/res1");
    assert_eq!(reservation.status, Some(ReservationStatus::Pending));
    assert_eq!(reservation.source, Some(ReservationSource::OpenApi));
    assert_eq!(
        reservation.starts_at,
        Some(Utc.with_ymd_and_hms(2026, 11, 20, 15, 30, 0).unwrap())
    );
    let ends = Utc.with_ymd_and_hms(2026, 11, 20, 17, 30, 0).unwrap() + chrono::Duration::nanoseconds(123_456_789);
    assert_eq!(reservation.ends_at, Some(ends));
    let created = Utc.with_ymd_and_hms(2026, 11, 11, 10, 0, 0).unwrap() + chrono::Duration::milliseconds(500);
    assert_eq!(reservation.created_at, Some(created));
    assert_eq!(reservation.decided_at, None);
    assert_eq!(reservation.table.as_ref().unwrap().label.as_deref(), Some("T5"));
    let guest = reservation.guest.as_ref().unwrap();
    assert_eq!(guest.phone.as_deref(), Some("+994501234567"));
    assert_eq!(guest.email, None);
    assert_eq!(reservation.pre_order[0].qty, Some(2));
    assert_eq!(reservation.deposit_paid, Some(0.0));
    assert_eq!(reservation.child_chair, Some(true));
}

#[tokio::test]
async fn availability() {
    let t = setup();
    t.http.json(
        200,
        json!({"data": {
            "startsAt": "2026-11-20T15:30:00Z",
            "endsAt": "2026-11-20T17:30:00Z",
            "durationMinutes": 120,
            "openTime": "10:00",
            "closeTime": "23:00",
            "tables": [{"id": "t5", "label": "T5", "hallId": "h1", "zone": "Terrace", "seats": 4, "free": true}]
        }}),
    );

    let result = t
        .client
        .reservations()
        .availability(date(2026, 11, 20), NaiveTime::from_hms_opt(19, 30, 0).unwrap(), Some(4))
        .await
        .unwrap();

    let request = t.http.last();
    assert_eq!(path(&request), "/v1/reservations/availability");
    assert_eq!(
        query(&request),
        expect_query(&[("date", &["2026-11-20"]), ("time", &["19:30"]), ("guests", &["4"])])
    );
    assert_eq!(result.duration_minutes, Some(120));
    assert_eq!(result.tables[0].free, Some(true));

    t.http.json(200, json!({"data": {}}));
    t.client
        .reservations()
        .availability(date(2026, 11, 20), NaiveTime::from_hms_opt(9, 5, 0).unwrap(), None)
        .await
        .unwrap();
    assert_eq!(
        query(&t.http.last()),
        expect_query(&[("date", &["2026-11-20"]), ("time", &["09:05"])])
    );
}

#[tokio::test]
async fn create_reservation_posts_json_and_reports_created() {
    let t = setup();
    t.http.json(201, json!({"data": reservation()}));

    let result = t
        .client
        .reservations()
        .create(
            &booking()
                .child_chair(true)
                .pre_order(PreOrderLine::new("p1", 2))
                .pre_order(PreOrderLine::new("p2", 1).note("no onion"))
                .external_ref("acme-991"),
        )
        .await
        .unwrap();

    let request = t.http.last();
    assert_eq!(request.method, "POST");
    assert_eq!(request.url, "https://open-api.noosh24.com/v1/reservations");
    assert_eq!(request.header("content-type"), Some("application/json"));
    assert_eq!(
        body(&request),
        json!({
            "date": "2026-11-20",
            "time": "19:30",
            "guests": 4,
            "guestName": "Aysel Məmmədova",
            "phone": "+994501234567",
            "childChair": true,
            "externalRef": "acme-991",
            "preOrder": [{"itemId": "p1", "qty": 2}, {"itemId": "p2", "qty": 1, "note": "no onion"}]
        })
    );
    let raw = String::from_utf8(request.body.clone().unwrap()).unwrap();
    assert!(raw.contains("Məmmədova"));
    assert!(result.created);
    assert_eq!(result.reservation.code.as_deref(), Some("K7Q2"));
}

#[tokio::test]
async fn create_sends_every_optional_field_that_is_set() {
    let t = setup();
    t.http.json(201, json!({"data": {"id": "r2"}}));

    t.client
        .reservations()
        .create(
            &booking()
                .email("a@example.com")
                .table_id("t5")
                .zone("Terrace")
                .special_request("window")
                .allergy_note("nuts")
                .birthday(false),
        )
        .await
        .unwrap();

    assert_eq!(
        body(&t.http.last()),
        json!({
            "date": "2026-11-20",
            "time": "19:30",
            "guests": 4,
            "guestName": "Aysel Məmmədova",
            "phone": "+994501234567",
            "email": "a@example.com",
            "tableId": "t5",
            "zone": "Terrace",
            "specialRequest": "window",
            "allergyNote": "nuts",
            "birthday": false
        })
    );
}

#[tokio::test]
async fn create_with_known_external_ref_returns_the_existing_booking() {
    let t = setup();
    t.http.json(200, json!({"data": reservation()}));

    let result = t
        .client
        .reservations()
        .create(&booking().external_ref("acme-991"))
        .await
        .unwrap();

    assert!(!result.created);
    assert_eq!(result.reservation.id.as_deref(), Some("res1"));
}

#[tokio::test]
async fn create_with_external_ref_is_retried() {
    let t = setup();
    t.http.json_with(
        503,
        json!({"error": "temporarily_unavailable"}),
        &[("Retry-After", "0")],
    );
    t.http.json(201, json!({"data": reservation()}));

    let result = t
        .client
        .reservations()
        .create(&booking().external_ref("acme-991"))
        .await
        .unwrap();

    assert!(result.created);
    let requests = t.http.requests();
    assert_eq!(requests.len(), 2);
    assert_eq!(requests[0].body, requests[1].body);
    assert_eq!(t.sleeps.seconds(), vec![0.0]);
}

#[tokio::test]
async fn create_without_external_ref_is_never_retried() {
    let t = setup();
    t.http.json_with(
        503,
        json!({"error": "temporarily_unavailable"}),
        &[("Retry-After", "0")],
    );

    let error = t.client.reservations().create(&booking()).await.unwrap_err();
    assert!(error.is_server_error());
    assert_eq!(t.http.count(), 1);

    t.http.fail(noosh24::TransportError::connection("connection reset"));
    let error = t
        .client
        .reservations()
        .create(&booking().external_ref("   "))
        .await
        .unwrap_err();
    assert!(error.is_connection());
    assert_eq!(t.http.count(), 2);
    assert!(t.sleeps.seconds().is_empty());
}

#[tokio::test]
async fn table_taken() {
    let t = setup();
    t.http.json(
        409,
        json!({"error": "table_taken", "message": "Bu masa seçilən vaxt üçün artıq tutulub"}),
    );

    let error = t
        .client
        .reservations()
        .create(&booking().table_id("t5").external_ref("x"))
        .await
        .unwrap_err();

    assert!(error.is_table_taken());
    assert!(error.is_conflict());
    assert!(error.to_string().contains("artıq tutulub"));
    assert_eq!(t.http.count(), 1);
}

#[tokio::test]
async fn cancel() {
    let t = setup();
    let mut cancelled = reservation();
    cancelled["status"] = json!("cancelled");
    t.http.json(200, json!({"data": cancelled}));

    let reservation = t.client.reservations().cancel("res1").await.unwrap();

    let request = t.http.last();
    assert_eq!(request.method, "POST");
    assert_eq!(request.url, "https://open-api.noosh24.com/v1/reservations/res1/cancel");
    assert_eq!(request.body, None);
    assert_eq!(request.header("content-type"), None);
    assert_eq!(reservation.status, Some(ReservationStatus::Cancelled));
}

#[tokio::test]
async fn orders_bills_payments_and_z_report() {
    let t = setup();
    t.http.json(
        200,
        json!({"data": {
            "id": "o1",
            "number": "A-12",
            "dailyNumber": 12,
            "kind": "delivery",
            "status": "ready",
            "subtotal": 30,
            "items": [{"id": "i1", "productId": "p1", "name": "Plov", "qty": 2, "price": 15, "comp": false}],
            "delivery": {
                "status": "accepted",
                "platform": {"id": "wolt", "name": "Wolt", "ref": "W-1"},
                "fee": 2,
                "acceptedAt": "2026-11-11T09:00:00Z"
            }
        }}),
    );
    t.http.json(
        200,
        json!({"data": {"id": "b1", "status": "paid", "orderIds": ["o1", "o2"], "total": 45.5, "closedAt": null}}),
    );
    t.http.json(
        200,
        json!({"data": {
            "id": "pay1",
            "method": "card",
            "amount": 20,
            "card": {"maskedPan": "4169********1234", "scheme": "visa", "bank": "Kapital"},
            "platform": null
        }}),
    );
    t.http.json(200, json!({"data": {"date": "2026-11-10", "cash": 120.5}}));

    let order = t.client.orders().get("o1").await.unwrap();
    let bill = t.client.orders().get_bill("b1").await.unwrap();
    let payment = t.client.payments().get("pay1").await.unwrap();
    let z = t.client.payments().z_report(Some(date(2026, 11, 10))).await.unwrap();

    let delivery = order.delivery.as_ref().unwrap();
    assert_eq!(delivery.platform.as_ref().unwrap().name.as_deref(), Some("Wolt"));
    assert_eq!(delivery.platform.as_ref().unwrap().reference.as_deref(), Some("W-1"));
    assert_eq!(delivery.fee, Some(2.0));
    assert_eq!(
        delivery.accepted_at,
        Some(Utc.with_ymd_and_hms(2026, 11, 11, 9, 0, 0).unwrap())
    );
    assert_eq!(order.kind, Some(noosh24::OrderKind::Delivery));
    assert_eq!(order.daily_number, Some(12));
    assert_eq!(order.items[0].price, Some(15.0));
    assert_eq!(order.items[0].comp, Some(false));
    assert_eq!(bill.order_ids, vec!["o1", "o2"]);
    assert_eq!(bill.status, Some(noosh24::BillStatus::Paid));
    assert_eq!(bill.closed_at, None);
    assert_eq!(payment.method, Some(PaymentMethod::Card));
    assert_eq!(
        payment.card.as_ref().unwrap().masked_pan.as_deref(),
        Some("4169********1234")
    );
    assert_eq!(payment.platform, None);
    assert_eq!(z["cash"], json!(120.5));
    assert_eq!(query(&t.http.last()), expect_query(&[("date", &["2026-11-10"])]));
    let paths: Vec<_> = t.http.requests().iter().map(path).collect();
    assert_eq!(
        paths,
        vec!["/v1/orders/o1", "/v1/bills/b1", "/v1/payments/pay1", "/v1/reports/z"]
    );

    t.http.json(200, json!({"data": {"cash": 1}}));
    t.client.payments().z_report(None).await.unwrap();
    assert_eq!(t.http.last().url, "https://open-api.noosh24.com/v1/reports/z");
}

#[tokio::test]
async fn lists_for_orders_bills_payments_and_reservations() {
    let t = setup();
    for _ in 0..4 {
        t.http.json(200, page(json!([{"id": "x"}]), 1, 20, 0));
    }

    assert_eq!(t.client.orders().list(ListParams::new()).await.unwrap().total, 1);
    assert_eq!(t.client.orders().list_bills(ListParams::new()).await.unwrap().len(), 1);
    assert!(!t.client.payments().list(ListParams::new()).await.unwrap().has_more());
    assert_eq!(
        t.client
            .reservations()
            .list(ListParams::new().limit(5))
            .await
            .unwrap()
            .items[0]
            .id
            .as_deref(),
        Some("x")
    );
    let paths: Vec<_> = t.http.requests().iter().map(path).collect();
    assert_eq!(
        paths,
        vec!["/v1/orders", "/v1/bills", "/v1/payments", "/v1/reservations"]
    );
    assert_eq!(t.http.requests()[0].url, "https://open-api.noosh24.com/v1/orders");
}

#[tokio::test]
async fn tables_loyalty_stock_and_reviews() {
    let t = setup();
    t.http.json(
        200,
        json!({"data": {"items": [{"id": "t1", "label": "T1", "status": "occupied", "billTotal": 42.1}], "total": 1}}),
    );
    t.http.json(
        200,
        json!({"data": {"stampsNeeded": 8, "earnBy": "visit", "rewardProductIds": ["p1"]}}),
    );
    t.http.json(
        200,
        page(json!([{"id": "card1", "stamps": 5, "lastVisitAt": null}]), 1, 100, 0),
    );
    t.http.json(
        200,
        page(
            json!([{"id": "ing1", "name": "Rice", "stock": 12, "byStore": {"s1": 10, "s2": 2.5}}]),
            1,
            20,
            0,
        ),
    );
    t.http.json(
        200,
        page(json!([{"id": "mv1", "qty": -2.5, "reason": "sale"}]), 1, 20, 0),
    );
    t.http.json(
        200,
        json!({"data": {"items": [{"id": "s1", "name": "Main", "isDefault": true, "stations": ["hot"]}], "total": 1}}),
    );
    t.http.json(
        200,
        page(
            json!([{"id": "rv1", "overall": 4.5, "ratings": {"food": 5, "service": 4}, "reply": null}]),
            1,
            20,
            0,
        ),
    );
    t.http
        .json(200, page(json!([{"id": "cu1", "name": "Aysel"}]), 1, 20, 0));

    let table = &t.client.tables().list().await.unwrap()[0];
    assert_eq!(table.bill_total, Some(42.1));
    assert_eq!(table.status, Some(noosh24::TableStatus::Occupied));
    let program = t.client.loyalty().get_program().await.unwrap();
    assert_eq!(program.stamps_needed, Some(8));
    assert_eq!(program.earn_by, Some(noosh24::LoyaltyProgramEarnBy::Visit));
    assert_eq!(program.reward_product_ids, vec!["p1"]);
    let cards = t.client.loyalty().list_cards(ListParams::new()).await.unwrap();
    assert!(!cards.has_more());
    assert_eq!(cards.items[0].last_visit_at, None);
    let ingredients = t.client.stock().list_ingredients(ListParams::new()).await.unwrap();
    assert_eq!(ingredients.items[0].by_store.get("s1"), Some(&10.0));
    assert_eq!(ingredients.items[0].by_store.get("s2"), Some(&2.5));
    assert_eq!(ingredients.items[0].by_store.len(), 2);
    let moves = t.client.stock().list_moves(ListParams::new()).await.unwrap();
    assert_eq!(moves.items[0].qty, Some(-2.5));
    assert_eq!(t.client.stock().list_stores().await.unwrap()[0].is_default, Some(true));
    let review = t
        .client
        .reviews()
        .list(ListParams::new())
        .await
        .unwrap()
        .items
        .remove(0);
    let ratings = review.ratings.unwrap();
    assert_eq!(ratings.food, Some(5.0));
    assert_eq!(ratings.price, None);
    assert_eq!(review.reply, None);
    let customers = t.client.customers().list(ListParams::new()).await.unwrap();
    assert_eq!(customers.items[0].name.as_deref(), Some("Aysel"));
    let paths: Vec<_> = t.http.requests().iter().map(path).collect();
    assert_eq!(
        paths,
        vec![
            "/v1/tables",
            "/v1/loyalty/program",
            "/v1/loyalty/cards",
            "/v1/stock/ingredients",
            "/v1/stock/moves",
            "/v1/stock/stores",
            "/v1/reviews",
            "/v1/customers"
        ]
    );
}

#[tokio::test]
async fn halls() {
    let t = setup();
    t.http.json(
        200,
        json!({"data": {"items": [{"id": "h1", "name": "Main", "position": 1}], "total": 1}}),
    );

    let halls = t.client.tables().list_halls().await.unwrap();

    assert_eq!(halls[0].position, Some(1));
    assert_eq!(path(&t.http.last()), "/v1/halls");
}

#[tokio::test]
async fn models_tolerate_missing_and_unknown_fields() {
    let t = setup();
    t.http.json(
        201,
        json!({"data": {"id": "res9", "code": "ZZ11", "status": "pending", "brandNew": 1}}),
    );

    let result = t.client.reservations().create(&booking()).await.unwrap();

    assert!(result.created);
    assert_eq!(result.reservation.code.as_deref(), Some("ZZ11"));
    assert_eq!(result.reservation.guest, None);
    assert!(result.reservation.pre_order.is_empty());
    assert_eq!(result.reservation.extra["brandNew"], json!(1));
}

#[tokio::test]
async fn models_tolerate_wrong_types_and_unknown_enum_values() {
    let t = setup();
    t.http.json(
        200,
        json!({"data": {
            "id": 42,
            "status": "teleported",
            "guests": "four",
            "depositPaid": true,
            "birthday": 1,
            "startsAt": "not a date",
            "table": "T5",
            "preOrder": [null, 3, {"qty": 2.9}],
            "guest": {"name": ["x"]}
        }}),
    );

    let reservation = t.client.reservations().get("res1").await.unwrap();

    assert_eq!(reservation.id.as_deref(), Some("42"));
    assert_eq!(
        reservation.status,
        Some(ReservationStatus::Unknown("teleported".into()))
    );
    assert_eq!(reservation.status.as_ref().unwrap().as_str(), "teleported");
    assert_eq!(reservation.guests, None);
    assert_eq!(reservation.deposit_paid, None);
    assert_eq!(reservation.birthday, Some(true));
    assert_eq!(reservation.starts_at, None);
    assert_eq!(reservation.table, None);
    assert_eq!(reservation.pre_order.len(), 1);
    assert_eq!(reservation.pre_order[0].qty, Some(2));
    assert_eq!(reservation.guest.unwrap().name, None);
}

#[tokio::test]
async fn models_serialize_back_to_camel_case() {
    let t = setup();
    t.http.json(200, json!({"data": product()}));

    let product = t.client.menu().get_product("p1", &[]).await.unwrap();
    let value = serde_json::to_value(&product).unwrap();

    assert_eq!(value["prepMinutes"], json!(20));
    assert_eq!(value["modifierGroups"][0]["modifiers"][0]["priceDelta"], json!(2.5));
    assert_eq!(value["translations"]["en"]["name"], json!("Pilaf"));
    assert!(value.get("vatRate").is_none());
    let again: Product = serde_json::from_value(value).unwrap();
    assert_eq!(again, product);
}
