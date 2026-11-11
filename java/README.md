<div align="center">

<a href="https://developer.noosh24.com"><img src="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup.svg" alt="Noosh24" width="260"></a>

# Noosh24 Open API for Java and Kotlin

**The official Java and Kotlin client for the [Noosh24 Open API](https://developer.noosh24.com).**<br>
Menu, reservations, orders and bills, payments and the Z-report, tables, customers, loyalty, stock and reviews of a Noosh24 venue, plus creating and cancelling reservations.

<a href="https://github.com/noosh24/sdks/actions/workflows/java.yml"><img src="https://github.com/noosh24/sdks/actions/workflows/java.yml/badge.svg" alt="CI"></a> <img src="https://img.shields.io/badge/Java-21%2B-ED8B00?logo=openjdk&logoColor=white" alt="Java 21+"> <img src="https://img.shields.io/badge/Maven%20Central-com.noosh24%3Anoosh24--open--api-DC4A38" alt="Maven Central"> <a href="https://github.com/noosh24/sdks/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>

[Developer site](https://developer.noosh24.com) · [API reference](https://developer.noosh24.com/reference) · [All SDKs](https://github.com/noosh24/sdks) · [Report an issue](https://github.com/noosh24/sdks/issues)

</div>

> [!IMPORTANT]
> **Keep the API key on your server.** A key belongs to one venue and opens its data: guests' phone numbers, payments, and writing reservations. Never put it in a browser, a mobile app or a public repository.

**Contents:** [Requirements](#requirements) · [Install](#install) · [Quick start](#quick-start) · [Options](#options) · [Resources](#resources) · [Lists, filters and pages](#lists-filters-and-pages) · [Reservations](#reservations) · [Errors](#errors) · [Retries and rate limits](#retries-and-rate-limits) · [Kotlin](#kotlin) · [Development](#development) · [License](#license)

## Requirements

- Java 21 or newer (tested on 21, 25 and 27). Uses the JDK's `java.net.http.HttpClient`; one runtime dependency, Jackson 3 (`tools.jackson.core:jackson-databind`), plus the JSpecify nullness annotations.
- Immutable records for every response, with JSpecify `@Nullable` so Kotlin sees `String?`, `Double?` and so on.
- Works from Kotlin as is (see [Kotlin](#kotlin)).

## Install

Gradle (Kotlin DSL):

```kotlin
dependencies {
    implementation("com.noosh24:noosh24-open-api:0.1.0")
}
```

Maven:

```xml
<dependency>
  <groupId>com.noosh24</groupId>
  <artifactId>noosh24-open-api</artifactId>
  <version>0.1.0</version>
</dependency>
```

## Quick start

```java
import static com.noosh24.openapi.Where.where;

import com.noosh24.openapi.Noosh24Client;
import com.noosh24.openapi.Page;
import com.noosh24.openapi.ProductListParams;
import com.noosh24.openapi.model.Product;
import com.noosh24.openapi.model.Whoami;

try (Noosh24Client noosh = new Noosh24Client(System.getenv("NOOSH24_API_KEY"))) {
    Whoami me = noosh.whoami();
    System.out.println(me.restaurant().name() + " " + me.key().scopes());

    Page<Product> page = noosh.menu().listProducts(ProductListParams.builder()
            .where(where().eq("category", "Salads").eq("available", true))
            .sort("price desc")
            .limit(50)
            .build());
    for (Product product : page) {
        System.out.println(product.name() + " " + product.price());
    }
    System.out.println(page.total() + " products match");
}
```

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser or a mobile app.

## Options

```java
Noosh24Client noosh = Noosh24Client.builder()
        .apiKey("nsk_...")
        .baseUrl("https://open-api.noosh24.com/v1")
        .timeout(Duration.ofSeconds(30))
        .maxRetries(2)
        .userAgent("acme-pos/2.1")
        .build();
```

`timeout` applies to each HTTP attempt. `httpClient(HttpClient)` takes your own `java.net.http.HttpClient` (proxies, custom TLS, executors). `transport(HttpTransport)` replaces the HTTP layer entirely: implement its one method, `Response send(Request)`, to route calls through another HTTP library or to fake the API in your tests. `sleeper(Sleeper)` replaces the wait between retries (the default is `Thread::sleep`); tests pass `d -> {}` or record the durations.

The client is thread-safe and meant to be shared. It implements `AutoCloseable`: `close()` shuts down the `HttpClient` the client created itself and leaves a client or transport you passed in alone.

## Resources

| Group | Methods |
| --- | --- |
| `whoami()` | the venue, the key's scopes and the venue's modules |
| `menu()` | `listCategories()`, `listProducts(params)`, `iterateProducts(params)`, `getProduct(id, expand...)`, `getStopList()` |
| `reservations()` | `list(params)`, `iterate(params)`, `get(id)`, `availability(date, time, guests)`, `create(NewReservation)`, `cancel(id)` |
| `orders()` | `list(params)`, `iterate(params)`, `get(id)`, `listBills(params)`, `iterateBills(params)`, `getBill(id)` |
| `payments()` | `list(params)`, `iterate(params)`, `get(id)`, `zReport(date)` |
| `tables()` | `list()`, `listHalls()` |
| `customers()` | `list(params)`, `iterate(params)`, `get(id)` |
| `loyalty()` | `getProgram()`, `listCards(params)`, `iterateCards(params)` |
| `stock()` | `listIngredients(params)`, `iterateIngredients(params)`, `listMoves(params)`, `iterateMoves(params)`, `listStores()` |
| `reviews()` | `list(params)`, `iterate(params)` |

Every `params` argument is optional. Responses are records in `com.noosh24.openapi.model` (`Product`, `Reservation`, `Order`, ...) with the API's camelCase names as accessors: `product.prepMinutes()`, `reservation.startsAt()`. Scalars are boxed and `null` when the API leaves them out; lists and maps are never `null` (empty instead). Timestamps are `OffsetDateTime` in UTC with the API's full nanosecond precision, money is `Double` in AZN. `model.raw()` holds the JSON as the API sent it, including fields this version of the SDK does not know yet. `zReport()` returns the report as a `Map<String, Object>`.

Every model also has `Model.from(JsonNode)`, and the records carry `@JsonIgnoreProperties(ignoreUnknown = true)`, so you can parse stored API JSON with either.

## Lists, filters and pages

List methods take `ListParams` (`limit`, `offset`, `sort`, `where`); products take `ProductListParams`, which adds `expand` (`ProductExpand.MODIFIER_GROUPS`, `ProductExpand.TRANSLATIONS`). They return a `Page<T>` with `items()`, `total()`, `limit()`, `offset()`, `hasMore()` and `nextOffset()`; a page is `Iterable`.

```java
Page<Order> orders = noosh.orders().list(ListParams.builder()
        .where("status = 'served' AND createdAt >= '2026-11-01'")
        .sort("createdAt desc")
        .limit(100)
        .build());
```

`where` is AND only, and field names are the API's camelCase names. Build it with `Where` so strings and dates are quoted correctly:

```java
Where condition = where()
        .eq("status", "confirmed")
        .gte("startsAt", OffsetDateTime.of(2026, 11, 20, 0, 0, 0, 0, ZoneOffset.ofHours(4)))
        .in("zone", "Terrace", "Chef's table");
```

`Where` takes strings, numbers, booleans, `LocalDate`, `OffsetDateTime`, `ZonedDateTime` and `Instant`; a `LocalDateTime`, `null`, `NaN` or an empty `in` list is an `IllegalArgumentException`.

The `iterate*()` methods return a `PagedIterable<T>` that walks every page and fetches the next page only when you reach it. Use it in a for-each loop or as a `Stream`:

```java
for (Payment payment : noosh.payments().iterate(ListParams.builder().where("createdAt >= '2026-11-01'").build())) {
    ...
}

double cash = noosh.payments().iterate().stream()
        .filter(p -> "cash".equals(p.method()) && p.amount() != null)
        .mapToDouble(Payment::amount)
        .sum();
```

`offset` stops at 10000. For bigger exports, narrow `where` by date and walk one window at a time.

## Reservations

```java
TableAvailability free = noosh.reservations().availability(LocalDate.of(2026, 11, 20), "19:30", 4);

try {
    CreateReservationResult result = noosh.reservations().create(NewReservation.builder()
            .date(LocalDate.of(2026, 11, 20))
            .time("19:30")
            .guests(4)
            .guestName("Aysel Məmmədova")
            .phone("+994501234567")
            .tableId(free.tables().get(0).id())
            .addPreOrder("0b6f3c1e", 2)
            .externalRef("acme-booking-991")
            .build());

    System.out.println(result.reservation().code() + (result.created() ? " created" : " already existed"));
    noosh.reservations().cancel(result.reservation().id());
} catch (TableTakenException e) {
    ...
}
```

A booking lands as `pending` and the venue confirms it. Always send `externalRef` (your own booking id): sending the same `externalRef` again returns the booking that already exists instead of making a second one, so a create is safe to retry. The client retries a create only when it carries an `externalRef`. You can cancel only bookings your key created.

## Errors

Every exception is unchecked. Every API error is a subclass of `ApiException` with `getStatus()`, `getCode()` (the API's `error` field), `getMessage()`, `getHeaders()` (lower-cased names) and `getBody()`. Branch on the class or on `getCode()`, not on the message.

| `code` | Exception | Parent |
| --- | --- | --- |
| `validation_error` | `ValidationException` | `ApiException` |
| `no_api_key` | `NoApiKeyException` | `AuthenticationException` |
| `invalid_api_key` | `InvalidApiKeyException` | `AuthenticationException` |
| `insufficient_scope` | `InsufficientScopeException` | `PermissionDeniedException` |
| `module_not_enabled` | `ModuleNotEnabledException` | `PermissionDeniedException` |
| `venue_suspended` | `VenueSuspendedException` | `PermissionDeniedException` |
| `not_your_reservation` | `NotYourReservationException` | `PermissionDeniedException` |
| `not_found` | `NotFoundException` | `ApiException` |
| `table_not_found` | `TableNotFoundException` | `NotFoundException` |
| `table_taken` | `TableTakenException` | `ConflictException` |
| `cannot_cancel` | `CannotCancelException` | `ConflictException` |
| `outside_hours`, `in_the_past`, `table_too_small` | `OutsideHoursException`, `InThePastException`, `TableTooSmallException` | `UnprocessableException` |
| `rate_limit_exceeded` | `RateLimitException` (`getRetryAfter()`, an `OptionalInt`) | `ApiException` |
| `temporarily_unavailable` | `TemporarilyUnavailableException` | `ServerException` |

An unknown code falls back to the class for its status (`AuthenticationException` for 401, `ConflictException` for 409 and so on, `ServerException` for any 5xx). A network failure throws `ApiConnectionException`; a timeout throws `ApiTimeoutException`, a subclass of it. All of them extend `Noosh24Exception`, a `RuntimeException`. Bad arguments (an empty key or id, a bad `where`) throw `IllegalArgumentException`.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504`, and on network errors and timeouts, the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ...) and tries again, up to `maxRetries` times. It never waits more than 60 seconds; a longer `Retry-After` is thrown to you as a `RateLimitException`. Reads, cancels and creates with an `externalRef` are retried; a create without an `externalRef` is not.

## Kotlin

The SDK is plain Java with JSpecify nullness, so Kotlin gets real nullable types and needs no extra artifact:

```kotlin
Noosh24Client.builder().apiKey(System.getenv("NOOSH24_API_KEY")).build().use { noosh ->
    val page = noosh.menu().listProducts(
        ProductListParams.builder().where(Where.where().eq("available", true)).limit(50).build(),
    )
    page.forEach { println("${it.name} ${it.price ?: 0.0}") }

    for (customer in noosh.customers().iterate()) println(customer.phone)
}
```

`in` is a keyword in Kotlin, so call the `Where` method with backticks: ``Where.where().`in`("zone", "Terrace", "Hall")``.

## Development

No local JDK is needed; the Gradle wrapper runs inside the official Temurin images:

```bash
docker run --rm -u "$(id -u):$(id -g)" -e GRADLE_USER_HOME=/cache -e HOME=/tmp \
  -v "$HOME/.cache/noosh24-gradle:/cache" -v "$PWD:/work" -w /work \
  eclipse-temurin:21-jdk ./gradlew --no-daemon build
```

With a JDK 21+ installed, `./gradlew build` runs the tests, the Javadoc and the jars. The models come from `tools/gen_java.py` (it reads the table in `tools/gen_models.py`): run `python3 tools/gen_java.py` from the repository root after a spec change.

## License

MIT
