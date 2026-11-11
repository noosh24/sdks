mod common;

use common::{setup, setup_with};
use noosh24::{ApiError, Error, ErrorCode, ErrorKind, ListParams};
use serde_json::json;

const CASES: &[(u16, Option<&str>, ErrorKind)] = &[
    (400, Some("validation_error"), ErrorKind::Validation),
    (401, Some("no_api_key"), ErrorKind::Authentication),
    (401, Some("invalid_api_key"), ErrorKind::Authentication),
    (403, Some("insufficient_scope"), ErrorKind::PermissionDenied),
    (403, Some("module_not_enabled"), ErrorKind::PermissionDenied),
    (403, Some("venue_suspended"), ErrorKind::PermissionDenied),
    (403, Some("not_your_reservation"), ErrorKind::PermissionDenied),
    (404, Some("not_found"), ErrorKind::NotFound),
    (404, Some("table_not_found"), ErrorKind::NotFound),
    (409, Some("table_taken"), ErrorKind::Conflict),
    (409, Some("cannot_cancel"), ErrorKind::Conflict),
    (422, Some("outside_hours"), ErrorKind::Unprocessable),
    (422, Some("in_the_past"), ErrorKind::Unprocessable),
    (422, Some("table_too_small"), ErrorKind::Unprocessable),
    (429, Some("rate_limit_exceeded"), ErrorKind::RateLimit),
    (503, Some("temporarily_unavailable"), ErrorKind::Server),
    (403, Some("something_new"), ErrorKind::PermissionDenied),
    (409, Some("something_new"), ErrorKind::Conflict),
    (500, Some("query_failed"), ErrorKind::Server),
    (418, None, ErrorKind::Other),
];

#[tokio::test]
async fn maps_error_codes() {
    for &(status, code, kind) in CASES {
        let t = setup_with(|b| b.max_retries(0));
        let body = match code {
            Some(code) => json!({"error": code, "message": "Mesaj"}),
            None => json!({"nope": true}),
        };
        t.http.json(status, body);

        let error = t.client.customers().get("c1").await.unwrap_err();

        let Error::Api(api) = &error else {
            panic!("{status} {code:?}: not an API error: {error:?}");
        };
        assert_eq!(api.status, status, "{code:?}");
        assert_eq!(api.code.as_ref().map(ErrorCode::as_str), code, "{status}");
        assert_eq!(api.kind(), kind, "{status} {code:?}");
        assert_eq!(error.kind(), Some(kind));
        let message = code.map_or(format!("HTTP {status}"), |_| "Mesaj".to_owned());
        assert_eq!(api.message, message);
        assert_eq!(error.to_string(), message);
    }
}

#[test]
fn known_codes_are_typed_and_unknown_codes_are_kept() {
    let cases = [
        ("validation_error", ErrorCode::ValidationError),
        ("no_api_key", ErrorCode::NoApiKey),
        ("invalid_api_key", ErrorCode::InvalidApiKey),
        ("insufficient_scope", ErrorCode::InsufficientScope),
        ("module_not_enabled", ErrorCode::ModuleNotEnabled),
        ("venue_suspended", ErrorCode::VenueSuspended),
        ("not_your_reservation", ErrorCode::NotYourReservation),
        ("not_found", ErrorCode::NotFound),
        ("table_not_found", ErrorCode::TableNotFound),
        ("table_taken", ErrorCode::TableTaken),
        ("cannot_cancel", ErrorCode::CannotCancel),
        ("outside_hours", ErrorCode::OutsideHours),
        ("in_the_past", ErrorCode::InThePast),
        ("table_too_small", ErrorCode::TableTooSmall),
        ("rate_limit_exceeded", ErrorCode::RateLimitExceeded),
        ("temporarily_unavailable", ErrorCode::TemporarilyUnavailable),
    ];
    for (text, code) in cases {
        assert_eq!(ErrorCode::from(text), code);
        assert_eq!(code.as_str(), text);
        assert!(code.kind().is_some());
    }
    let unknown = ErrorCode::from("something_new");
    assert_eq!(unknown, ErrorCode::Unknown("something_new".to_owned()));
    assert_eq!(unknown.kind(), None);
}

#[test]
fn predicates_follow_the_code_and_the_status() {
    let error = |status: u16, code: &str| -> Error {
        ApiError::from_response(status, Default::default(), json!({"error": code}).to_string()).into()
    };
    assert!(error(400, "validation_error").is_validation());
    assert!(error(401, "no_api_key").is_no_api_key());
    assert!(error(401, "invalid_api_key").is_invalid_api_key());
    assert!(error(401, "invalid_api_key").is_authentication());
    assert!(error(403, "insufficient_scope").is_insufficient_scope());
    assert!(error(403, "module_not_enabled").is_module_not_enabled());
    assert!(error(403, "venue_suspended").is_venue_suspended());
    assert!(error(403, "not_your_reservation").is_not_your_reservation());
    assert!(error(403, "anything").is_permission_denied());
    assert!(error(404, "table_not_found").is_table_not_found());
    assert!(error(404, "table_not_found").is_not_found());
    assert!(error(409, "table_taken").is_table_taken());
    assert!(error(409, "table_taken").is_conflict());
    assert!(error(409, "cannot_cancel").is_cannot_cancel());
    assert!(!error(409, "cannot_cancel").is_table_taken());
    assert!(error(422, "outside_hours").is_outside_hours());
    assert!(error(422, "in_the_past").is_in_the_past());
    assert!(error(422, "table_too_small").is_table_too_small());
    assert!(error(422, "table_too_small").is_unprocessable());
    assert!(error(429, "rate_limit_exceeded").is_rate_limited());
    assert_eq!(error(429, "rate_limit_exceeded").retry_after(), None);
    assert!(error(503, "temporarily_unavailable").is_temporarily_unavailable());
    assert!(error(502, "bad_gateway").is_server_error());
    assert!(!Error::InvalidArgument("x".into()).is_table_taken());
    assert_eq!(Error::InvalidArgument("x".into()).kind(), None);
}

#[test]
fn message_falls_back_to_code_then_status() {
    let only_code = ApiError::from_response(404, Default::default(), r#"{"error":"not_found"}"#);
    assert_eq!(only_code.message, "not_found");
    let nothing = ApiError::from_response(502, Default::default(), "Bad Gateway");
    assert_eq!(nothing.message, "HTTP 502");
    assert_eq!(nothing.kind(), ErrorKind::Server);
    assert_eq!(nothing.body, "Bad Gateway");
}

#[tokio::test]
async fn headers_are_lower_cased() {
    let t = setup_with(|b| b.max_retries(0));
    t.http
        .json_with(404, json!({"error": "not_found"}), &[("X-Request-Id", "abc")]);

    let error = t.client.orders().get("o1").await.unwrap_err();

    let api = error.api().unwrap();
    assert_eq!(api.headers.get("x-request-id").map(String::as_str), Some("abc"));
    assert_eq!(api.header("X-REQUEST-ID"), Some("abc"));
}

#[tokio::test]
async fn validation_error_is_not_retried() {
    let t = setup();
    t.http.json(
        400,
        json!({"error": "validation_error", "message": "\"nope\" is not a filterable field on this resource"}),
    );

    let error = t
        .client
        .menu()
        .list_products(ListParams::new().where_("nope = 1"))
        .await
        .unwrap_err();

    assert!(error.is_validation());
    assert!(error.to_string().contains("not a filterable field"));
    assert_eq!(t.http.count(), 1);
}
