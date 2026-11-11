mod common;

use std::time::Duration;

use common::{Mock, setup, setup_with};
use noosh24::{Client, DEFAULT_BASE_URL, Error, ErrorCode, TransportError, VERSION};
use serde_json::json;

#[tokio::test]
async fn sends_key_and_headers_to_default_base_url() {
    let t = setup();
    t.http.json(
        200,
        json!({"data": {
            "restaurant": {"id": "r1", "name": "Masago", "slug": "masago"},
            "key": {"id": "k1", "name": "Wolt", "prefix": "nsk_Ab3dE9xQ", "scopes": ["menu:read", "orders:read"]},
            "subscription": {"status": "active", "modules": ["loyalty"]},
            "features": {"loyalty": true, "inventory": false}
        }}),
    );

    let me = t.client.whoami().await.unwrap();

    let request = t.http.last();
    assert_eq!(request.method, "GET");
    assert_eq!(request.url, "https://open-api.noosh24.com/v1/whoami");
    assert_eq!(request.header("authorization"), Some("Bearer nsk_test_123"));
    assert_eq!(request.header("accept"), Some("application/json"));
    assert_eq!(
        request.header("user-agent"),
        Some(format!("noosh24-rust/{VERSION}").as_str())
    );
    assert_eq!(request.header("content-type"), None);
    assert_eq!(request.body, None);
    assert_eq!(request.timeout, Duration::from_secs(30));
    assert_eq!(me.restaurant.unwrap().name.as_deref(), Some("Masago"));
    assert_eq!(me.key.unwrap().scopes, vec!["menu:read", "orders:read"]);
    assert_eq!(
        me.subscription.unwrap().status,
        Some(noosh24::SubscriptionStatus::Active)
    );
    let features = me.features.unwrap();
    assert_eq!(features.loyalty, Some(true));
    assert_eq!(features.inventory, Some(false));
}

#[tokio::test]
async fn custom_base_url_user_agent_and_timeout() {
    let t = setup_with(|b| {
        b.base_url("http://localhost:8080/v1/")
            .user_agent("acme-pos/2.1")
            .timeout(Duration::from_secs(5))
    });
    t.http.json(200, json!({"data": {}}));

    t.client.whoami().await.unwrap();

    let request = t.http.last();
    assert_eq!(request.url, "http://localhost:8080/v1/whoami");
    assert_eq!(
        request.header("user-agent"),
        Some(format!("acme-pos/2.1 noosh24-rust/{VERSION}").as_str())
    );
    assert_eq!(request.timeout, Duration::from_secs(5));
}

#[test]
fn defaults() {
    let client = Client::new("nsk_x").unwrap();
    assert_eq!(client.base_url(), DEFAULT_BASE_URL);
    assert_eq!(client.timeout(), Duration::from_secs(30));
    assert_eq!(client.max_retries(), 2);
    assert_eq!(client.user_agent(), format!("noosh24-rust/{VERSION}"));
    assert!(!format!("{client:?}").contains("nsk_x"));
}

#[test]
fn rejects_empty_key_and_bad_base_url() {
    assert!(matches!(Client::new("  "), Err(Error::InvalidArgument(_))));
    assert!(matches!(Client::builder().build(), Err(Error::InvalidArgument(_))));
    assert!(matches!(
        Client::builder().api_key("nsk_x").base_url("not a url").build(),
        Err(Error::InvalidArgument(_))
    ));
}

#[tokio::test]
async fn retries_rate_limit_after_retry_after() {
    let t = setup();
    t.http.json_with(
        429,
        json!({"error": "rate_limit_exceeded", "message": "slow down"}),
        &[("Retry-After", "3")],
    );
    t.http.json(200, json!({"data": {"items": [], "total": 0}}));

    assert!(t.client.tables().list().await.unwrap().is_empty());
    assert_eq!(t.http.count(), 2);
    assert_eq!(t.sleeps.seconds(), vec![3.0]);
}

#[tokio::test]
async fn gives_up_after_max_retries() {
    let t = setup_with(|b| b.max_retries(1));
    t.http.json_with(
        429,
        json!({"error": "rate_limit_exceeded", "message": "slow down"}),
        &[("Retry-After", "1")],
    );
    t.http.json_with(
        429,
        json!({"error": "rate_limit_exceeded", "message": "slow down"}),
        &[("Retry-After", "7")],
    );

    let error = t.client.tables().list().await.unwrap_err();

    assert!(error.is_rate_limited());
    let api = error.api().unwrap();
    assert_eq!(api.status, 429);
    assert_eq!(api.code, Some(ErrorCode::RateLimitExceeded));
    assert_eq!(api.retry_after(), Some(7));
    assert_eq!(api.header("Retry-After"), Some("7"));
    assert_eq!(error.to_string(), "slow down");
    assert_eq!(t.http.count(), 2);
    assert_eq!(t.sleeps.seconds(), vec![1.0]);
}

#[tokio::test]
async fn does_not_wait_longer_than_a_minute() {
    let t = setup();
    t.http
        .json_with(429, json!({"error": "rate_limit_exceeded"}), &[("Retry-After", "120")]);

    let error = t.client.tables().list().await.unwrap_err();

    assert!(error.is_rate_limited());
    assert_eq!(error.retry_after(), Some(120));
    assert_eq!(t.http.count(), 1);
    assert!(t.sleeps.seconds().is_empty());
}

#[tokio::test]
async fn backs_off_on_temporarily_unavailable() {
    let t = setup();
    for _ in 0..3 {
        t.http
            .json(503, json!({"error": "temporarily_unavailable", "message": "try again"}));
    }

    let error = t.client.tables().list_halls().await.unwrap_err();

    assert!(error.is_temporarily_unavailable());
    assert!(error.is_server_error());
    assert_eq!(t.http.count(), 3);
    assert_eq!(t.sleeps.seconds(), vec![0.5, 1.0]);
}

#[tokio::test]
async fn retries_connection_errors_on_reads() {
    let t = setup_with(|b| b.max_retries(1));
    t.http.fail(TransportError::connection("connection reset"));
    t.http.json(
        200,
        json!({"data": {"items": [{"id": "h1", "name": "Main", "position": 1}], "total": 1}}),
    );

    let halls = t.client.tables().list_halls().await.unwrap();
    assert_eq!(halls[0].name.as_deref(), Some("Main"));
    assert_eq!(t.sleeps.seconds(), vec![0.5]);

    t.http
        .fail(TransportError::connection("connection reset"))
        .fail(TransportError::connection("connection reset"));
    let error = t.client.tables().list_halls().await.unwrap_err();
    assert!(matches!(error, Error::Connection { .. }));
    assert!(error.is_connection());
    assert!(!error.is_timeout());
    assert!(error.to_string().contains("connection reset"));
    assert!(std::error::Error::source(&error).is_some());
}

#[tokio::test]
async fn timeout() {
    let t = setup_with(|b| b.max_retries(0));
    t.http.fail(TransportError::timeout("read timed out"));

    let error = t.client.whoami().await.unwrap_err();

    assert!(matches!(error, Error::Timeout { .. }));
    assert!(error.is_timeout());
    assert!(error.is_connection());
    assert_eq!(t.http.count(), 1);
}

#[tokio::test]
async fn timeouts_are_retried_on_reads() {
    let t = setup();
    t.http
        .fail(TransportError::timeout("read timed out"))
        .json(200, json!({"data": {}}));

    t.client.whoami().await.unwrap();

    assert_eq!(t.http.count(), 2);
    assert_eq!(t.sleeps.seconds(), vec![0.5]);
}

#[tokio::test]
async fn body_that_is_not_json_is_an_api_error() {
    let t = setup();
    t.http.raw(200, "<html>gateway</html>");

    let error = t.client.whoami().await.unwrap_err();

    let api = error.api().unwrap();
    assert_eq!(api.status, 200);
    assert_eq!(api.code, None);
    assert_eq!(api.body, "<html>gateway</html>");
}

#[tokio::test]
async fn body_without_data_is_an_api_error() {
    let t = setup();
    t.http.json(200, json!({"items": []}));

    let error = t.client.whoami().await.unwrap_err();

    assert!(error.to_string().contains("\"data\""));
}

#[tokio::test]
async fn builds_repeated_query_parameters() {
    let t = setup();
    t.http.json(200, common::page(json!([]), 0, 20, 0));

    t.client
        .orders()
        .list(
            noosh24::ListParams::new()
                .sort("price desc")
                .sort("name asc")
                .where_("a = 1"),
        )
        .await
        .unwrap();

    let url = t.http.last().url;
    assert!(
        url.ends_with("?sort=price%20desc&sort=name%20asc&where=a%20%3D%201"),
        "{url}"
    );
}

#[test]
fn the_mock_is_send_and_sync() {
    fn check<T: Send + Sync>() {}
    check::<Mock>();
    check::<Client>();
}
