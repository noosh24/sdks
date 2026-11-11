<div align="center">

<a href="https://developer.noosh24.com"><img src="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup.svg" alt="Noosh24" width="260"></a>

# Noosh24 Open API for C++

**The official C++ client for the [Noosh24 Open API](https://developer.noosh24.com).**<br>
Menu, reservations, orders and bills, payments and the Z-report, tables, customers, loyalty, stock and reviews of a Noosh24 venue, plus creating and cancelling reservations.

<a href="https://github.com/noosh24/sdks/actions/workflows/cpp.yml"><img src="https://github.com/noosh24/sdks/actions/workflows/cpp.yml/badge.svg" alt="CI"></a> <img src="https://img.shields.io/badge/C%2B%2B-20-00599C?logo=cplusplus&logoColor=white" alt="C++ 20"> <img src="https://img.shields.io/badge/CMake-noosh24-DC4A38" alt="CMake"> <a href="https://github.com/noosh24/sdks/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>

[Developer site](https://developer.noosh24.com) · [API reference](https://developer.noosh24.com/reference) · [All SDKs](https://github.com/noosh24/sdks) · [Report an issue](https://github.com/noosh24/sdks/issues)

</div>

> [!IMPORTANT]
> **Keep the API key on your server.** A key belongs to one venue and opens its data: guests' phone numbers, payments, and writing reservations. Never put it in a browser, a mobile app or a public repository.

**Contents:** [Requirements](#requirements) · [Install](#install) · [Quick start](#quick-start) · [Options](#options) · [Resources](#resources) · [Lists, filters and pages](#lists-filters-and-pages) · [Reservations](#reservations) · [Errors](#errors) · [Retries and rate limits](#retries-and-rate-limits) · [Development](#development) · [License](#license)

## Requirements

- C++20 or newer (also builds as C++23). Tested with GCC 14 and 16 on Linux and Apple clang 21 on macOS.
- CMake 3.25 or newer. Dependencies: libcurl (system) and nlohmann/json 3.12 (found with `find_package`, or fetched).
- Plain structs with `std::optional` fields for every response, `std::chrono` timestamps, exceptions for errors.

## Install

With CMake `FetchContent`:

```cmake
include(FetchContent)
FetchContent_Declare(noosh24
    GIT_REPOSITORY https://github.com/noosh24/sdks.git
    GIT_TAG cpp/v0.1.0
    SOURCE_SUBDIR cpp)
FetchContent_MakeAvailable(noosh24)

target_link_libraries(your_app PRIVATE noosh24::noosh24)
```

Or build and install it once, then use `find_package`:

```bash
cmake -S cpp -B build -DCMAKE_BUILD_TYPE=Release -DNOOSH24_BUILD_TESTS=OFF
cmake --build build
cmake --install build --prefix /usr/local
```

```cmake
find_package(noosh24 0.1 CONFIG REQUIRED)
target_link_libraries(your_app PRIVATE noosh24::noosh24)
```

You need the libcurl development files (`libcurl4-openssl-dev` on Debian and Ubuntu, `libcurl-devel` on Fedora; macOS ships them with the SDK). `vcpkg.json` and `conanfile.py` describe the package for vcpkg and Conan.

## Quick start

```cpp
#include <cstdlib>
#include <iostream>

#include <noosh24/noosh24.hpp>

int main()
{
    noosh24::Client noosh{std::getenv("NOOSH24_API_KEY")};

    auto me = noosh.whoami();
    std::cout << me.restaurant->name.value_or("") << "\n";

    auto page = noosh.menu().list_products({
        .limit = 50,
        .sort = {"price desc"},
        .where = noosh24::where().eq("category", "Salads").eq("available", true),
    });
    for (const auto& product : page) {
        std::cout << product.name.value_or("") << " " << product.price.value_or(0) << "\n";
    }
    std::cout << page.total << " products match\n";
}
```

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser or a mobile app.

## Options

```cpp
using namespace std::chrono_literals;

noosh24::Client noosh{"nsk_...", noosh24::ClientOptions{
    .base_url = "https://open-api.noosh24.com/v1",
    .timeout = 30s,
    .max_retries = 2,
    .user_agent = "acme-pos/2.1",
}};
```

`timeout` is a `std::chrono::milliseconds`. `transport` takes your own `std::shared_ptr<noosh24::Transport>` (a proxy, custom TLS, tests); the default is `noosh24::CurlTransport`. `sleep` takes a `std::function<void(std::chrono::milliseconds)>` used between retries, so tests do not wait. The client is movable, not copyable, and calls are synchronous. An empty key throws `std::invalid_argument`.

A transport implements one method:

```cpp
class RecordingTransport : public noosh24::Transport {
public:
    noosh24::Response send(const noosh24::Request& request) override;
};
```

It throws `noosh24::ConnectionError` (or `noosh24::TimeoutError`) when the request does not reach the API.

## Resources

| Group | Methods |
| --- | --- |
| `whoami()` | the venue, the key's scopes and the venue's modules |
| `menu()` | `list_categories()`, `list_products()`, `iterate_products()`, `get_product(id, expand)`, `get_stop_list()` |
| `reservations()` | `list()`, `iterate()`, `get(id)`, `availability(date, time, guests)`, `create(NewReservation)`, `cancel(id)` |
| `orders()` | `list()`, `iterate()`, `get(id)`, `list_bills()`, `iterate_bills()`, `get_bill(id)` |
| `payments()` | `list()`, `iterate()`, `get(id)`, `z_report(date)` |
| `tables()` | `list()`, `list_halls()` |
| `customers()` | `list()`, `iterate()`, `get(id)` |
| `loyalty()` | `get_program()`, `list_cards()`, `iterate_cards()` |
| `stock()` | `list_ingredients()`, `iterate_ingredients()`, `list_moves()`, `iterate_moves()`, `list_stores()` |
| `reviews()` | `list()`, `iterate()` |

Responses are structs (`noosh24::Product`, `noosh24::Reservation`, `noosh24::Order`, ...) with snake_case members: `product.prep_minutes`, `reservation.starts_at`. Scalars are `std::optional`, lists are `std::vector` and maps are `std::map<std::string, T>`, empty when the API leaves them out. Timestamps are `noosh24::Timestamp` (`std::chrono::sys_time<std::chrono::microseconds>`, UTC), money is `double` in AZN. `model.raw` holds the JSON as the API sent it (`nlohmann::json`), including fields this version of the SDK does not know yet. `z_report()` returns the report as a `nlohmann::json` object.

## Lists, filters and pages

List methods take a `noosh24::ListParams` (`limit`, `offset`, `sort`, `where`) or, for products, a `noosh24::ProductListParams` that adds `expand`. Designated initializers follow the member order (`limit`, `offset`, `sort`, `where`, `expand`). They return a `noosh24::Page<T>` with `items`, `total`, `limit`, `offset`, `has_more()` and `next_offset()`; a page is a range over its items.

```cpp
auto orders = noosh.orders().list({
    .limit = 100,
    .sort = {"createdAt desc"},
    .where = "status = 'served' AND createdAt >= '2026-11-01'",
});
```

`where` is AND only, and field names are the API's camelCase names. Build it with `noosh24::where()` so strings and dates are quoted correctly:

```cpp
using namespace std::chrono;

std::string condition = noosh24::where()
    .eq("status", "confirmed")
    .gte("startsAt", noosh24::OffsetDateTime{local_days{2026y / November / 20}, 4h})
    .lt("visitedOn", 2026y / November / 2)
    .in("zone", {"Terrace", "Chef's table"});
```

Strings, integers, doubles, booleans, `std::chrono::year_month_day` and `sys_days` (dates), `noosh24::OffsetDateTime` and `sys_time` (timestamps) are accepted. A bad field name, an empty `in()` list, a NaN or infinite number and `nullptr` throw `std::invalid_argument`.

The `iterate*()` methods return an input range that walks every page and fetches the next page only when you reach it:

```cpp
for (const auto& payment : noosh.payments().iterate({.where = "createdAt >= '2026-11-01'"})) {
    ...
}
```

`offset` stops at 10000. For bigger exports, narrow `where` by date and walk one window at a time.

## Reservations

```cpp
auto free = noosh.reservations().availability("2026-11-20", "19:30", 4);

try {
    auto result = noosh.reservations().create({
        .date = "2026-11-20",
        .time = "19:30",
        .guests = 4,
        .guest_name = "Aysel Məmmədova",
        .phone = "+994501234567",
        .table_id = free.tables.at(0).id,
        .pre_order = {{.item_id = "0b6f3c1e", .qty = 2}},
        .external_ref = "acme-booking-991",
    });
    std::cout << result.reservation.code.value_or("") << (result.created ? " created" : " already existed") << "\n";
    noosh.reservations().cancel(*result.reservation.id);
} catch (const noosh24::TableTakenError&) {
    ...
}
```

A booking lands as `pending` and the venue confirms it. Always send `external_ref` (your own booking id): sending the same `external_ref` again returns the booking that already exists instead of making a second one, so a create is safe to retry. The client retries a create only when it carries an `external_ref`. You can cancel only bookings your key created.

## Errors

Every API error is a subclass of `noosh24::ApiError` with `status()`, `code()` (the API's `error` field), `message()`, `headers()` (lower-cased names) and `body()`. Branch on the class or on `code()`, not on the message.

| `code` | Exception | Parent |
| --- | --- | --- |
| `validation_error` | `ValidationError` | `ApiError` |
| `no_api_key` | `NoApiKeyError` | `AuthenticationError` |
| `invalid_api_key` | `InvalidApiKeyError` | `AuthenticationError` |
| `insufficient_scope` | `InsufficientScopeError` | `PermissionDeniedError` |
| `module_not_enabled` | `ModuleNotEnabledError` | `PermissionDeniedError` |
| `venue_suspended` | `VenueSuspendedError` | `PermissionDeniedError` |
| `not_your_reservation` | `NotYourReservationError` | `PermissionDeniedError` |
| `not_found` | `NotFoundError` | `ApiError` |
| `table_not_found` | `TableNotFoundError` | `NotFoundError` |
| `table_taken` | `TableTakenError` | `ConflictError` |
| `cannot_cancel` | `CannotCancelError` | `ConflictError` |
| `outside_hours`, `in_the_past`, `table_too_small` | `OutsideHoursError`, `InThePastError`, `TableTooSmallError` | `UnprocessableError` |
| `rate_limit_exceeded` | `RateLimitError` (`retry_after()`) | `ApiError` |
| `temporarily_unavailable` | `TemporarilyUnavailableError` | `ServerError` |

An unknown code falls back to the class for its status (`AuthenticationError` 401, `PermissionDeniedError` 403, `NotFoundError` 404, `ConflictError` 409, `UnprocessableError` 422, `ServerError` 5xx). A network failure throws `noosh24::ConnectionError`; a timeout throws `noosh24::TimeoutError`, a subclass of it. All of them extend `noosh24::Error`, which is a `std::runtime_error`.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504` the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ...) and tries again, up to `max_retries` times. It never waits more than 60 seconds; a longer `Retry-After` is thrown to you as a `RateLimitError`. Reads, cancels and creates with an `external_ref` are retried; a create without an `external_ref` is not.

## Development

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build --output-on-failure
```

Add `-DCMAKE_CXX_STANDARD=23` to build as C++23. On Linux with Docker:

```bash
docker run --rm -v "$PWD:/src:ro" gcc:latest bash -c \
  'apt-get update && apt-get install -y cmake libcurl4-openssl-dev &&
   cmake -S /src -B /b && cmake --build /b -j && ctest --test-dir /b'
```

The models in `include/noosh24/models.hpp` and `src/models.cpp` are generated by `python3 tools/gen_cpp.py` from the table in `tools/gen_models.py`. The tests replace the transport with a mock; the libcurl transport is tested against a loopback server.

## License

MIT
