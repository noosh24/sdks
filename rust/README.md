<div align="center">

<a href="https://developer.noosh24.com"><img src="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup.svg" alt="Noosh24" width="260"></a>

# Noosh24 Open API for Rust

**The official Rust client for the [Noosh24 Open API](https://developer.noosh24.com).**<br>
Menu, reservations, orders and bills, payments and the Z-report, tables, customers, loyalty, stock and reviews of a Noosh24 venue, plus creating and cancelling reservations.

<a href="https://github.com/noosh24/sdks/actions/workflows/rust.yml"><img src="https://github.com/noosh24/sdks/actions/workflows/rust.yml/badge.svg" alt="CI"></a> <img src="https://img.shields.io/badge/Rust-1.88%2B-000000?logo=rust&logoColor=white" alt="Rust 1.88+"> <img src="https://img.shields.io/badge/crates.io-noosh24-DC4A38" alt="crates.io"> <a href="https://github.com/noosh24/sdks/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>

[Developer site](https://developer.noosh24.com) · [API reference](https://developer.noosh24.com/reference) · [All SDKs](https://github.com/noosh24/sdks) · [Report an issue](https://github.com/noosh24/sdks/issues)

</div>

> [!IMPORTANT]
> **Keep the API key on your server.** A key belongs to one venue and opens its data: guests' phone numbers, payments, and writing reservations. Never put it in a browser, a mobile app or a public repository.

**Contents:** [Requirements](#requirements) · [Install](#install) · [Quick start](#quick-start) · [Options](#options) · [Resources](#resources) · [Lists, filters and pages](#lists-filters-and-pages) · [Reservations](#reservations) · [Errors](#errors) · [Retries and rate limits](#retries-and-rate-limits) · [Development](#development) · [License](#license)

## Requirements

- Rust 1.88 or newer (edition 2024; tested on 1.88 and 1.99). Async on `tokio` with `reqwest` over rustls, no OpenSSL.
- Typed `serde` models for every response, `chrono` timestamps, one `Error` type.

## Install

```bash
cargo add noosh24
cargo add tokio --features macros,rt-multi-thread
cargo add futures
```

`futures` is only needed for the `StreamExt` / `TryStreamExt` helpers used with the `iterate*()` methods. `noosh24::chrono` re-exports the `chrono` version the models use.

## Quick start

```rust
use noosh24::{Client, ListParams, Where};

#[tokio::main]
async fn main() -> noosh24::Result<()> {
    let noosh = Client::new(std::env::var("NOOSH24_API_KEY").unwrap_or_default())?;

    let me = noosh.whoami().await?;
    println!("{:?} {:?}", me.restaurant.and_then(|r| r.name), me.key.map(|k| k.scopes));

    let page = noosh
        .menu()
        .list_products(ListParams {
            where_: Some(Where::new().eq("category", "Salads").eq("available", true).into()),
            sort: vec!["price desc".into()],
            limit: Some(50),
            ..Default::default()
        })
        .await?;
    for product in &page {
        println!("{:?} {:?}", product.name, product.price);
    }
    println!("{} products match", page.total);
    Ok(())
}
```

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser or a mobile app.

## Options

```rust
use std::time::Duration;

let noosh = noosh24::Client::builder()
    .api_key("nsk_...")
    .base_url("https://open-api.noosh24.com/v1")
    .timeout(Duration::from_secs(30))
    .max_retries(2)
    .user_agent("acme-pos/2.1")
    .build()?;
```

`http_client(reqwest::Client)` takes your own `reqwest` client (proxies, custom TLS). `transport(impl Transport)` replaces the HTTP layer entirely and `sleep(|duration| async { ... })` replaces the wait between retries; both are what the tests use. `Client` is cheap to clone and safe to share between tasks.

## Resources

| Group | Methods |
| --- | --- |
| `whoami()` | the venue, the key's scopes and the venue's modules |
| `menu()` | `list_categories()`, `list_products(params)`, `iterate_products(params)`, `get_product(id, &expand)`, `get_stop_list()` |
| `reservations()` | `list(params)`, `iterate(params)`, `get(id)`, `availability(date, time, guests)`, `create(&new_reservation)`, `cancel(id)` |
| `orders()` | `list(params)`, `iterate(params)`, `get(id)`, `list_bills(params)`, `iterate_bills(params)`, `get_bill(id)` |
| `payments()` | `list(params)`, `iterate(params)`, `get(id)`, `z_report(date)` |
| `tables()` | `list()`, `list_halls()` |
| `customers()` | `list(params)`, `iterate(params)`, `get(id)` |
| `loyalty()` | `get_program()`, `list_cards(params)`, `iterate_cards(params)` |
| `stock()` | `list_ingredients(params)`, `iterate_ingredients(params)`, `list_moves(params)`, `iterate_moves(params)`, `list_stores()` |
| `reviews()` | `list(params)`, `iterate(params)` |

Responses are `#[non_exhaustive]` structs (`Product`, `Reservation`, `Order`, ...) with snake_case fields: `product.prep_minutes`, `reservation.starts_at`. Every scalar field is an `Option`, lists and maps default to empty, so a missing or `null` field never fails a request. Timestamps are `chrono::DateTime<Utc>`, money is `f64` in AZN, and fields with a fixed set of values are enums with an `Unknown(String)` fallback (`ReservationStatus::Pending`, `PaymentMethod::Card`). `model.extra` holds the JSON fields this version of the SDK does not know yet, and every model serializes back to the API's camelCase JSON. `z_report()` returns the report as a `serde_json::Map`.

## Lists, filters and pages

List methods take a `ListParams` with `limit`, `offset`, `sort`, `where_` and, for products, `expand`. Build it as a struct with `..Default::default()` or with its chained setters. They return a `Page<T>` with `items`, `total`, `limit`, `offset`, `has_more()` and `next_offset()`; a page is iterable.

```rust
let orders = noosh
    .orders()
    .list(
        ListParams::new()
            .where_("status = 'served' AND createdAt >= '2026-11-01'")
            .sort("createdAt desc")
            .limit(100),
    )
    .await?;
```

`where` is AND only, and field names are the API's camelCase names. Build it with `Where` so strings and dates are quoted correctly; a bad field name, an empty `in_()` list or a non-finite number comes back as `Error::InvalidArgument` before any request is sent:

```rust
use noosh24::chrono::{FixedOffset, TimeZone};
use noosh24::Where;

let baku = FixedOffset::east_opt(4 * 3600).unwrap();
let condition = Where::new()
    .eq("status", "confirmed")
    .gte("startsAt", baku.with_ymd_and_hms(2026, 11, 20, 0, 0, 0).unwrap())
    .in_("zone", ["Terrace", "Chef's table"]);
```

The `iterate*()` methods return a `Stream` that walks every page and fetches the next page only when you reach it:

```rust
use futures::TryStreamExt;

let mut payments = noosh.payments().iterate(ListParams::new().where_("createdAt >= '2026-11-01'"));
while let Some(payment) = payments.try_next().await? {
    println!("{:?} {:?}", payment.id, payment.amount);
}
```

`offset` stops at 10000. For bigger exports, narrow `where` by date and walk one window at a time.

## Reservations

```rust
use noosh24::chrono::{NaiveDate, NaiveTime};
use noosh24::{NewReservation, PreOrderLine};

let date = NaiveDate::from_ymd_opt(2026, 11, 20).unwrap();
let time = NaiveTime::from_hms_opt(19, 30, 0).unwrap();
let free = noosh.reservations().availability(date, time, Some(4)).await?;

let booking = NewReservation::new(date, time, 4, "Aysel Məmmədova", "+994501234567")
    .table_id(free.tables[0].id.clone().unwrap_or_default())
    .pre_order(PreOrderLine::new("0b6f3c1e", 2))
    .external_ref("acme-booking-991");

match noosh.reservations().create(&booking).await {
    Ok(result) => {
        println!("{:?} {}", result.reservation.code, if result.created { "created" } else { "already existed" });
        noosh.reservations().cancel(result.reservation.id.as_deref().unwrap_or_default()).await?;
    }
    Err(error) if error.is_table_taken() => println!("pick another table"),
    Err(error) => return Err(error),
}
```

A booking lands as `pending` and the venue confirms it. Always send `external_ref` (your own booking id): sending the same `external_ref` again returns the booking that already exists instead of making a second one, so a create is safe to retry. The client retries a create only when it carries an `external_ref`. You can cancel only bookings your key created.

## Errors

Every method returns `noosh24::Result<T>`. `Error` has four variants: `Api(ApiError)`, `Connection { .. }`, `Timeout { .. }` (a timeout is also a connection error: `is_connection()` is true for both) and `InvalidArgument(String)`. `ApiError` carries `status`, `code` (`Option<ErrorCode>`, the API's `error` field), `message`, `headers` (lower-cased) and `body`. `kind()` gives the status-level group. Branch on the predicates or on `code`, not on the message; every predicate is available on both `Error` and `ApiError`.

| `code` | `ErrorCode` | Predicate | `ErrorKind` |
| --- | --- | --- | --- |
| `validation_error` | `ValidationError` | `is_validation()` | `Validation` |
| `no_api_key` | `NoApiKey` | `is_no_api_key()` | `Authentication` |
| `invalid_api_key` | `InvalidApiKey` | `is_invalid_api_key()` | `Authentication` |
| `insufficient_scope` | `InsufficientScope` | `is_insufficient_scope()` | `PermissionDenied` |
| `module_not_enabled` | `ModuleNotEnabled` | `is_module_not_enabled()` | `PermissionDenied` |
| `venue_suspended` | `VenueSuspended` | `is_venue_suspended()` | `PermissionDenied` |
| `not_your_reservation` | `NotYourReservation` | `is_not_your_reservation()` | `PermissionDenied` |
| `not_found` | `NotFound` | `is_not_found()` | `NotFound` |
| `table_not_found` | `TableNotFound` | `is_table_not_found()` | `NotFound` |
| `table_taken` | `TableTaken` | `is_table_taken()` | `Conflict` |
| `cannot_cancel` | `CannotCancel` | `is_cannot_cancel()` | `Conflict` |
| `outside_hours`, `in_the_past`, `table_too_small` | `OutsideHours`, `InThePast`, `TableTooSmall` | `is_outside_hours()`, `is_in_the_past()`, `is_table_too_small()` | `Unprocessable` |
| `rate_limit_exceeded` | `RateLimitExceeded` | `is_rate_limited()` (`retry_after()`) | `RateLimit` |
| `temporarily_unavailable` | `TemporarilyUnavailable` | `is_temporarily_unavailable()` | `Server` |

A code this version does not know is `ErrorCode::Unknown(String)` and takes its `kind()` from the status (`is_permission_denied()`, `is_conflict()`, `is_unprocessable()`, `is_authentication()`, `is_server_error()` for any 5xx); anything else is `ErrorKind::Other`.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504`, and on connection errors and timeouts, the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ... up to 8 s) and tries again, up to `max_retries` times. It never waits more than 60 seconds; a longer `Retry-After` is returned to you as a rate-limit error with `retry_after()` set. Reads, cancels and creates with an `external_ref` are retried; a create without an `external_ref` is not.

## Development

```bash
cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo test
```

The tests use an in-memory `Transport` and a local `wiremock` server; they never reach the network. The models in `src/models.rs` are generated: after a spec change, update the table in `tools/gen_models.py` and run `python3 tools/gen_rust.py` from the repository root.

## License

MIT
