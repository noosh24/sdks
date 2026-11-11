<div align="center">

<a href="https://developer.noosh24.com"><img src="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup.svg" alt="Noosh24" width="260"></a>

# Noosh24 Open API for Swift

**The official Swift client for the [Noosh24 Open API](https://developer.noosh24.com).**<br>
Menu, reservations, orders and bills, payments and the Z-report, tables, customers, loyalty, stock and reviews of a Noosh24 venue, plus creating and cancelling reservations.

<a href="https://github.com/noosh24/sdks/actions/workflows/swift.yml"><img src="https://github.com/noosh24/sdks/actions/workflows/swift.yml/badge.svg" alt="CI"></a> <img src="https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white" alt="Swift 6.0+"> <img src="https://img.shields.io/badge/SwiftPM-Noosh24-DC4A38" alt="SwiftPM"> <a href="https://github.com/noosh24/sdks/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>

[Developer site](https://developer.noosh24.com) · [API reference](https://developer.noosh24.com/reference) · [All SDKs](https://github.com/noosh24/sdks) · [Report an issue](https://github.com/noosh24/sdks/issues)

</div>

> [!CAUTION]
> **Server-side only.** A Noosh24 API key opens the venue's whole account: guests' phone numbers, payments, and writing reservations. Never ship it inside a mobile, desktop or web app that leaves your hands, because it can be pulled out of the bundle. Let the app call your own backend, and use this SDK there.

**Contents:** [Requirements](#requirements) · [Install](#install) · [Quick start](#quick-start) · [Options](#options) · [Resources](#resources) · [Lists, filters and pages](#lists-filters-and-pages) · [Reservations](#reservations) · [Errors](#errors) · [Retries and rate limits](#retries-and-rate-limits) · [Development](#development) · [License](#license)

## Requirements

- Swift 6.0 or newer, Swift 6 language mode with strict concurrency (tested on 6.0.3 and 6.4.2). No dependencies beyond Foundation.
- Linux (FoundationNetworking), macOS 15+, iOS 16+.
- `async`/`await` throughout; the client and every model are `Sendable`.

## Install

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/noosh24/noosh24-swift.git", from: "0.1.0"),
],
targets: [
    .target(name: "App", dependencies: [.product(name: "Noosh24", package: "noosh24-swift")]),
]
```

Or in Xcode: File → Add Package Dependencies, enter `https://github.com/noosh24/noosh24-swift.git` and add the `Noosh24` library to your target. The SDK is developed in the [noosh24/sdks](https://github.com/noosh24/sdks) monorepo (folder `swift/`); `noosh24-swift` is its read-only mirror with plain `vX.Y.Z` tags.

## Quick start

```swift
import Foundation
import Noosh24

let noosh = try Noosh24Client(apiKey: ProcessInfo.processInfo.environment["NOOSH24_API_KEY"] ?? "")

let me = try await noosh.whoami()
print(me.restaurant?.name ?? "", me.key?.scopes ?? [])

let page = try await noosh.menu.listProducts(
    limit: 50,
    sort: "price desc",
    where: try Where().eq("category", "Salads").eq("available", true)
)
for product in page {
    print(product.name ?? "", product.price ?? 0)
}
print(page.total, "products match")
```

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser or a mobile app.

## Options

```swift
let noosh = try Noosh24Client(
    apiKey: "nsk_...",
    configuration: .init(
        baseURL: URL(string: "https://open-api.noosh24.com/v1")!,
        timeout: .seconds(30),
        maxRetries: 2,
        userAgent: "acme-pos/2.1"
    )
)
```

An empty or blank key throws `Noosh24Error.invalidArgument`. `transport:` takes your own `Noosh24Transport` (a protocol with one `send(_:) async throws -> Noosh24HTTPResponse` method), for example an AsyncHTTPClient adapter or a mock in tests; the default is `URLSessionTransport`, which uses an ephemeral `URLSession` and does not follow redirects. `URLSessionTransport(session:)` wraps a session you configured yourself. `sleep:` replaces the wait between retries.

## Resources

| Group | Methods |
| --- | --- |
| `whoami()` | the venue, the key's scopes and the venue's modules |
| `menu` | `listCategories()`, `listProducts()`, `iterateProducts()`, `getProduct(_:expand:)`, `getStopList()` |
| `reservations` | `list()`, `iterate()`, `get(_:)`, `availability(date:time:guests:)`, `create(_:)`, `cancel(_:)` |
| `orders` | `list()`, `iterate()`, `get(_:)`, `listBills()`, `iterateBills()`, `getBill(_:)` |
| `payments` | `list()`, `iterate()`, `get(_:)`, `zReport(date:)` |
| `tables` | `list()`, `listHalls()` |
| `customers` | `list()`, `iterate()`, `get(_:)` |
| `loyalty` | `getProgram()`, `listCards()`, `iterateCards()` |
| `stock` | `listIngredients()`, `iterateIngredients()`, `listMoves()`, `iterateMoves()`, `listStores()` |
| `reviews` | `list()`, `iterate()` |

Responses are structs (`Product`, `Reservation`, `Order`, ...) that are `Codable`, `Sendable` and `Hashable`, with the API's camelCase names: `product.prepMinutes`, `reservation.startsAt`. Every property is optional, so a field the API leaves out is `nil` instead of a decoding failure. Timestamps are `Date` (RFC 3339 with up to 9 fractional digits; `JSONDecoder.DateDecodingStrategy.noosh24` is the same parser for your own decoding), money is `Double` in AZN. Status-like fields are enums with an `unknown(String)` case, so a new value never breaks decoding (the subscription status `none` is `.noSubscription`, so it never clashes with `Optional.none`). `model.raw` holds the JSON as the API sent it, including fields this version of the SDK does not know yet. `zReport(date:)` returns a free-form `[String: JSONValue]`.

## Lists, filters and pages

List methods take `limit`, `offset`, `sort`, `where` and, for products, `expand`. They return a `Page` with `items`, `total`, `limit`, `offset`, `hasMore` and `nextOffset`; a page is a `RandomAccessCollection` of its items.

```swift
let orders = try await noosh.orders.list(
    limit: 100,
    sort: ["createdAt desc"],
    where: "status = 'served' AND createdAt >= '2026-11-01'"
)
```

`where` is AND only, and field names are the API's camelCase names. It takes a plain `String` or a `Where`; build a `Where` so strings and dates are quoted correctly:

```swift
let baku = TimeZone(identifier: "Asia/Baku")!
let condition = try Where()
    .eq("status", "confirmed")
    .gte("startsAt", ZonedDateTime(Date(), in: baku))
    .lt("visitedOn", PlainDate(year: 2026, month: 11, day: 2))
    .in("zone", ["Terrace", "Chef's table"])
```

`Where` takes `String`, integers, `Double`, `Bool`, `Date` (sent in UTC), `ZonedDateTime` (sent with its offset) and `PlainDate`; a bad field name, an empty `in` list, `nil` or a non-finite number throws `Noosh24Error.invalidArgument`. `sort` takes one string or an array; `expand` takes `[.modifierGroups, .translations]`.

The `iterate*()` methods return a `PagedSequence`, an `AsyncSequence` that walks every page and fetches the next page only when you reach it:

```swift
for try await payment in noosh.payments.iterate(where: "createdAt >= '2026-11-01'") {
    print(payment.amount ?? 0)
}
let everyCustomer = try await noosh.customers.iterate(limit: 100).collect()
```

`offset` stops at 10000. For bigger exports, narrow `where` by date and walk one window at a time.

## Reservations

```swift
let free = try await noosh.reservations.availability(date: "2026-11-20", time: "19:30", guests: 4)

do {
    let result = try await noosh.reservations.create(
        NewReservation(
            date: PlainDate(year: 2026, month: 11, day: 20),
            time: "19:30",
            guests: 4,
            guestName: "Aysel Məmmədova",
            phone: "+994501234567",
            tableId: free.tables?.first?.id,
            preOrder: [PreOrderLine(itemId: "0b6f3c1e", qty: 2)],
            externalRef: "acme-booking-991"
        )
    )
    print(result.reservation.code ?? "", result.created ? "created" : "already existed")
    _ = try await noosh.reservations.cancel(result.reservation.id ?? "")
} catch let error as Noosh24Error where error.code == .tableTaken {
    print("pick another table")
}
```

A booking lands as `pending` and the venue confirms it. Always send `externalRef` (your own booking id): sending the same `externalRef` again returns the booking that already exists instead of making a second one, so a create is safe to retry. The client retries a create only when it carries an `externalRef`. You can cancel only bookings your key created.

## Errors

Every failure is a `Noosh24Error`:

- `.api(Noosh24APIError)`: the API answered with an error, or with a body that is not JSON or has no `data`.
- `.connection(message:underlying:)`: the API could not be reached.
- `.timeout(message:)`: the request timed out (`isConnectionError` is true for both).
- `.invalidArgument(String)`: a blank key, an empty id or a bad `Where`.

`Noosh24APIError` carries `status`, `code` (a `Noosh24ErrorCode`, the API's `error` field), `message`, `headers` (lower-cased names), `body`, `kind` (the status-level group) and `retryAfter`. Branch on `code` or `kind`, not on the message. An `error` value this SDK does not know becomes `.unknown("...")` and its `kind` comes from the status (any `5xx` is `.server`, an unknown status is `.other`).

| `error` | `Noosh24ErrorCode` | `kind` |
| --- | --- | --- |
| `validation_error` | `.validationError` | `.validation` (400) |
| `no_api_key` | `.noApiKey` | `.authentication` (401) |
| `invalid_api_key` | `.invalidApiKey` | `.authentication` (401) |
| `insufficient_scope` | `.insufficientScope` | `.permissionDenied` (403) |
| `module_not_enabled` | `.moduleNotEnabled` | `.permissionDenied` (403) |
| `venue_suspended` | `.venueSuspended` | `.permissionDenied` (403) |
| `not_your_reservation` | `.notYourReservation` | `.permissionDenied` (403) |
| `not_found` | `.notFound` | `.notFound` (404) |
| `table_not_found` | `.tableNotFound` | `.notFound` (404) |
| `table_taken` | `.tableTaken` | `.conflict` (409) |
| `cannot_cancel` | `.cannotCancel` | `.conflict` (409) |
| `outside_hours`, `in_the_past`, `table_too_small` | `.outsideHours`, `.inThePast`, `.tableTooSmall` | `.unprocessable` (422) |
| `rate_limit_exceeded` | `.rateLimitExceeded` (`retryAfter`) | `.rateLimit` (429) |
| `temporarily_unavailable` | `.temporarilyUnavailable` | `.server` (5xx) |

```swift
do {
    _ = try await noosh.customers.get("c1")
} catch let error as Noosh24Error {
    switch error {
    case .api(let api) where api.kind == .notFound: print("no such customer")
    case .api(let api) where api.kind == .rateLimit: print("retry in", api.retryAfter ?? 1, "s")
    case .timeout, .connection: print("network:", error.message)
    default: throw error
    }
}
```

Task cancellation is passed through as `CancellationError` and is never retried.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504`, and on connection errors and timeouts, the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ... up to 8 s) and tries again, up to `maxRetries` times. It never waits more than 60 seconds; a longer `Retry-After` is thrown to you as a `.rateLimitExceeded` error with `retryAfter` set. Reads, cancels and creates with an `externalRef` are retried; a create without an `externalRef` is not.

## Development

```bash
swift build -c release
swift test
docker run --rm -v "$PWD":/pkg -w /pkg swift:6.0 swift test --scratch-path /tmp/build
docker run --rm -v "$PWD":/pkg -w /pkg swift:latest swift test --scratch-path /tmp/build
```

The models in `Sources/Noosh24/Models.swift` and `Enums.swift` are generated: run `python3 tools/gen_swift.py` from the repository root after a change to `tools/gen_models.py`.

## License

MIT
