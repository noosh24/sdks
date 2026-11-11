use std::sync::{Arc, Mutex};
use std::time::Duration;

use chrono::{NaiveDate, NaiveTime};
use noosh24::{Client, ClientBuilder, Error, ListParams, NewReservation, VERSION, Where};
use serde_json::json;
use wiremock::matchers::{body_json, header, method, path, query_param};
use wiremock::{Mock, MockServer, ResponseTemplate};

fn builder(base_url: &str, sleeps: &Arc<Mutex<Vec<Duration>>>) -> ClientBuilder {
    let recorded = sleeps.clone();
    Client::builder()
        .api_key("nsk_test_123")
        .base_url(format!("{base_url}/v1"))
        .sleep(move |duration| {
            recorded.lock().unwrap().push(duration);
            async {}
        })
}

#[tokio::test]
async fn talks_http_through_reqwest() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/v1/whoami"))
        .and(header("authorization", "Bearer nsk_test_123"))
        .and(header("accept", "application/json"))
        .and(header(
            "user-agent",
            format!("acme-pos/2.1 noosh24-rust/{VERSION}").as_str(),
        ))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({"data": {"restaurant": {"name": "Masago"}}})))
        .expect(1)
        .mount(&server)
        .await;
    Mock::given(method("GET"))
        .and(path("/v1/menu/products"))
        .and(query_param("where", "category = 'Chef''s' AND price >= 5"))
        .and(query_param("expand", "translations"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "data": {"items": [{"id": "p1", "name": "Plov", "price": 14}], "total": 1, "limit": 20, "offset": 0}
        })))
        .expect(1)
        .mount(&server)
        .await;
    Mock::given(method("POST"))
        .and(path("/v1/reservations"))
        .and(header("content-type", "application/json"))
        .and(body_json(json!({
            "date": "2026-11-20",
            "time": "19:30",
            "guests": 2,
            "guestName": "Aysel",
            "phone": "+994501234567",
            "externalRef": "acme-1"
        })))
        .respond_with(
            ResponseTemplate::new(201)
                .set_body_json(json!({"data": {"id": "r1", "code": "K7Q2", "status": "pending"}})),
        )
        .expect(1)
        .mount(&server)
        .await;
    let sleeps = Arc::new(Mutex::new(Vec::new()));
    let client = builder(&server.uri(), &sleeps)
        .user_agent("acme-pos/2.1")
        .build()
        .unwrap();

    let me = client.whoami().await.unwrap();
    let products = client
        .menu()
        .list_products(
            ListParams::new()
                .where_(Where::new().eq("category", "Chef's").gte("price", 5))
                .expand("translations"),
        )
        .await
        .unwrap();
    let created = client
        .reservations()
        .create(
            &NewReservation::new(
                NaiveDate::from_ymd_opt(2026, 11, 20).unwrap(),
                NaiveTime::from_hms_opt(19, 30, 0).unwrap(),
                2,
                "Aysel",
                "+994501234567",
            )
            .external_ref("acme-1"),
        )
        .await
        .unwrap();

    assert_eq!(me.restaurant.unwrap().name.as_deref(), Some("Masago"));
    assert_eq!(products.items[0].price, Some(14.0));
    assert!(created.created);
    let received = server.received_requests().await.unwrap();
    assert!(received[1].url.query().unwrap().contains("Chef%27%27s"));
    assert!(!received[1].url.query().unwrap().contains('+'));
}

#[tokio::test]
async fn retries_429_over_http() {
    let server = MockServer::start().await;
    Mock::given(path("/v1/tables"))
        .respond_with(
            ResponseTemplate::new(429)
                .insert_header("Retry-After", "0")
                .set_body_json(json!({"error": "rate_limit_exceeded", "message": "slow down"})),
        )
        .up_to_n_times(1)
        .with_priority(1)
        .mount(&server)
        .await;
    Mock::given(path("/v1/tables"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({"data": {"items": [{"id": "t1"}], "total": 1}})))
        .mount(&server)
        .await;
    let sleeps = Arc::new(Mutex::new(Vec::new()));
    let client = builder(&server.uri(), &sleeps).build().unwrap();

    let tables = client.tables().list().await.unwrap();

    assert_eq!(tables[0].id.as_deref(), Some("t1"));
    assert_eq!(server.received_requests().await.unwrap().len(), 2);
    assert_eq!(*sleeps.lock().unwrap(), vec![Duration::ZERO]);
}

#[tokio::test]
async fn api_errors_over_http_keep_headers_and_body() {
    let server = MockServer::start().await;
    Mock::given(path("/v1/reservations/r1/cancel"))
        .and(method("POST"))
        .respond_with(
            ResponseTemplate::new(409)
                .insert_header("X-Request-Id", "req-1")
                .set_body_json(json!({"error": "cannot_cancel", "message": "Already seated"})),
        )
        .mount(&server)
        .await;
    let sleeps = Arc::new(Mutex::new(Vec::new()));
    let client = builder(&server.uri(), &sleeps).build().unwrap();

    let error = client.reservations().cancel("r1").await.unwrap_err();

    assert!(error.is_cannot_cancel());
    let api = error.api().unwrap();
    assert_eq!(api.header("x-request-id"), Some("req-1"));
    assert!(api.body.contains("Already seated"));
    assert!(sleeps.lock().unwrap().is_empty());
}

#[tokio::test]
async fn non_json_body_over_http() {
    let server = MockServer::start().await;
    Mock::given(path("/v1/whoami"))
        .respond_with(ResponseTemplate::new(200).set_body_string("<html>gateway</html>"))
        .mount(&server)
        .await;
    let sleeps = Arc::new(Mutex::new(Vec::new()));
    let client = builder(&server.uri(), &sleeps).build().unwrap();

    let error = client.whoami().await.unwrap_err();

    assert_eq!(error.status(), Some(200));
    assert_eq!(error.code(), None);
}

#[tokio::test]
async fn times_out() {
    let server = MockServer::start().await;
    Mock::given(path("/v1/whoami"))
        .respond_with(
            ResponseTemplate::new(200)
                .set_body_json(json!({"data": {}}))
                .set_delay(Duration::from_secs(5)),
        )
        .mount(&server)
        .await;
    let sleeps = Arc::new(Mutex::new(Vec::new()));
    let client = builder(&server.uri(), &sleeps)
        .timeout(Duration::from_millis(100))
        .max_retries(1)
        .build()
        .unwrap();

    let error = client.whoami().await.unwrap_err();

    assert!(matches!(error, Error::Timeout { .. }), "{error:?}");
    assert!(error.is_connection());
    assert_eq!(*sleeps.lock().unwrap(), vec![Duration::from_millis(500)]);
}

#[tokio::test]
async fn connection_refused() {
    let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
    let address = listener.local_addr().unwrap();
    drop(listener);
    let sleeps = Arc::new(Mutex::new(Vec::new()));
    let client = builder(&format!("http://{address}"), &sleeps)
        .max_retries(2)
        .build()
        .unwrap();

    let error = client.tables().list_halls().await.unwrap_err();

    assert!(matches!(error, Error::Connection { .. }), "{error:?}");
    assert!(error.to_string().starts_with("Could not reach the Noosh24 API"));
    assert_eq!(
        *sleeps.lock().unwrap(),
        vec![Duration::from_millis(500), Duration::from_secs(1)]
    );
}

#[tokio::test]
async fn custom_reqwest_client() {
    let server = MockServer::start().await;
    Mock::given(path("/v1/halls"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({"data": {"items": [], "total": 0}})))
        .expect(1)
        .mount(&server)
        .await;
    let sleeps = Arc::new(Mutex::new(Vec::new()));
    let client = builder(&server.uri(), &sleeps)
        .http_client(reqwest::Client::new())
        .build()
        .unwrap();

    assert!(client.tables().list_halls().await.unwrap().is_empty());
}
