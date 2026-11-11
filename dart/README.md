<div align="center">

<a href="https://developer.noosh24.com"><img src="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup.svg" alt="Noosh24" width="260"></a>

# Noosh24 Open API for Dart

**The official Dart client for the [Noosh24 Open API](https://developer.noosh24.com).**<br>
Menu, reservations, orders and bills, payments and the Z-report, tables, customers, loyalty, stock and reviews of a Noosh24 venue, plus creating and cancelling reservations.

<a href="https://github.com/noosh24/sdks/actions/workflows/dart.yml"><img src="https://github.com/noosh24/sdks/actions/workflows/dart.yml/badge.svg" alt="CI"></a> <img src="https://img.shields.io/badge/Dart-3.11%2B-0175C2?logo=dart&logoColor=white" alt="Dart 3.11+"> <img src="https://img.shields.io/badge/pub.dev-noosh24-DC4A38" alt="pub.dev"> <a href="https://github.com/noosh24/sdks/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>

[Developer site](https://developer.noosh24.com) · [API reference](https://developer.noosh24.com/reference) · [All SDKs](https://github.com/noosh24/sdks) · [Report an issue](https://github.com/noosh24/sdks/issues)

</div>

> [!CAUTION]
> **Server-side only.** A Noosh24 API key opens the venue's whole account: guests' phone numbers, payments, and writing reservations. Never ship it inside a mobile, desktop or web app that leaves your hands, because it can be pulled out of the bundle. Let the app call your own backend, and use this SDK there.

**Contents:** [Requirements](#requirements) · [Install](#install) · [Quick start](#quick-start) · [Options](#options) · [Resources](#resources) · [Lists, filters and pages](#lists-filters-and-pages) · [Reservations](#reservations) · [Errors](#errors) · [Retries and rate limits](#retries-and-rate-limits) · [Development](#development) · [License](#license)

## Requirements

- Dart 3.11 or newer (tested on 3.11.6 and 3.14.0). One dependency: `package:http`.
- Immutable typed models for every response; iterate methods return lazy `Stream`s.

## Install

```bash
dart pub add noosh24
```

## Quick start

```dart
import 'dart:io';

import 'package:noosh24/noosh24.dart';

Future<void> main() async {
  final noosh = Noosh24Client(Platform.environment['NOOSH24_API_KEY']!);

  final me = await noosh.whoami();
  print('${me.restaurant?.name} ${me.key?.scopes}');

  final page = await noosh.menu.listProducts(
    where: Where().eq('category', 'Salads').eq('available', true),
    sort: 'price desc',
    limit: 50,
  );
  for (final product in page.items) {
    print('${product.name} ${product.price}');
  }
  print('${page.total} products match');

  noosh.close();
}
```

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser, a Flutter app or any other client.

## Options

```dart
import 'package:http/http.dart' as http;

final noosh = Noosh24Client(
  'nsk_...',
  baseUrl: 'https://open-api.noosh24.com/v1',
  timeout: const Duration(seconds: 30),
  maxRetries: 2,
  userAgent: 'acme-pos/2.1',
  httpClient: http.Client(),
  sleep: (duration) => Future<void>.delayed(duration),
);
```

`timeout` applies to each attempt. `httpClient` takes your own `http.Client` (proxies, custom TLS, `package:http/testing.dart` `MockClient` in tests); the SDK closes only a client it created itself, on `close()`. `sleep` is what the client awaits between retries, so tests can record the waits instead of sleeping.

## Resources

| Group | Methods |
| --- | --- |
| `whoami()` | the venue, the key's scopes and the venue's modules |
| `menu` | `listCategories()`, `listProducts()`, `iterateProducts()`, `getProduct(id, expand:)`, `getStopList()` |
| `reservations` | `list()`, `iterate()`, `get(id)`, `availability(date, time, guests:)`, `create(NewReservation)`, `cancel(id)` |
| `orders` | `list()`, `iterate()`, `get(id)`, `listBills()`, `iterateBills()`, `getBill(id)` |
| `payments` | `list()`, `iterate()`, `get(id)`, `zReport(date:)` |
| `tables` | `list()`, `listHalls()` |
| `customers` | `list()`, `iterate()`, `get(id)` |
| `loyalty` | `getProgram()`, `listCards()`, `iterateCards()` |
| `stock` | `listIngredients()`, `iterateIngredients()`, `listMoves()`, `iterateMoves()`, `listStores()` |
| `reviews` | `list()`, `iterate()` |

Every method returns a `Future`, except `iterate*()`, which return a `Stream`. Responses are immutable classes (`Product`, `Reservation`, `Order`, ...) with `final` fields named like the API: `product.prepMinutes`, `reservation.startsAt`. Scalar fields are nullable, lists and maps default to empty and are unmodifiable. Timestamps are `DateTime` values in UTC (fractions beyond microseconds are truncated), money is `double` in AZN. `model.raw` holds the JSON as the API sent it, including fields this version of the SDK does not know yet. `zReport()` returns a free-form `ZReport` (`Map<String, dynamic>`).

## Lists, filters and pages

List methods take `limit`, `offset`, `sort` (a `String` or a `List<String>`), `where` (a `String` or a `Where`) and, for products, `expand` (`ProductExpand.modifierGroups`, `ProductExpand.translations`). They return a `Page<T>` with `items`, `total`, `limit`, `offset`, `hasMore` and `nextOffset`.

```dart
final orders = await noosh.orders.list(
  where: "status = 'served' AND createdAt >= '2026-11-01'",
  sort: ['createdAt desc'],
  limit: 100,
);
```

`where` is AND only, and field names are the API's camelCase names. Build it with `Where` so strings and dates are quoted correctly. `in` is a reserved word in Dart, so the list operator is `isIn`:

```dart
final condition = Where()
    .eq('status', 'confirmed')
    .gte('startsAt', OffsetDateTime(DateTime.utc(2026, 11, 19, 20), const Duration(hours: 4)))
    .lt('visitedOn', CalendarDate(2026, 11, 21))
    .isIn('zone', ['Terrace', "Chef's table"]);
```

Values can be `String`, `int`, `double`, `bool`, `DateTime` (UTC is written with `Z`, local time with the machine's offset), `OffsetDateTime` (an instant written with the offset you choose, such as Baku's `+04:00`) and `CalendarDate` (a plain `YYYY-MM-DD` date).

The `iterate*()` methods walk every page and fetch the next page only when you reach it; nothing is requested until you listen:

```dart
await for (final payment in noosh.payments.iterate(where: "createdAt >= '2026-11-01'")) {
  print(payment.amount);
}
```

`offset` stops at 10000. For bigger exports, narrow `where` by date and walk one window at a time.

## Reservations

```dart
final free = await noosh.reservations.availability(CalendarDate(2026, 11, 20), '19:30', guests: 4);

try {
  final result = await noosh.reservations.create(
    NewReservation(
      date: CalendarDate(2026, 11, 20),
      time: '19:30',
      guests: 4,
      guestName: 'Aysel Məmmədova',
      phone: '+994501234567',
      tableId: free.tables.first.id,
      preOrder: const [PreOrderLine(itemId: '0b6f3c1e', qty: 2)],
      externalRef: 'acme-booking-991',
    ),
  );
  print('${result.reservation.code} ${result.created ? 'created' : 'already existed'}');
  await noosh.reservations.cancel(result.reservation.id!);
} on TableTakenException {
  ...
}
```

A booking lands as `pending` and the venue confirms it. Always send `externalRef` (your own booking id): sending the same `externalRef` again returns the booking that already exists instead of making a second one, so a create is safe to retry. The client retries a create only when it carries an `externalRef`. You can cancel only bookings your key created.

## Errors

Every API error is a subclass of `ApiException` with `status`, `code` (the API's `error` field), `message`, `headers` (lower-case names) and `body`. Branch on the class or on `code`, not on the message.

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
| `rate_limit_exceeded` | `RateLimitException` (`retryAfter`) | `ApiException` |
| `temporarily_unavailable` | `TemporarilyUnavailableException` | `ServerException` |

An unknown code falls back to its status class (`PermissionDeniedException` for a new 403 code, `ServerException` for any 5xx). A network failure throws `ApiConnectionException`; a timeout throws `ApiTimeoutException`, a subclass of it. All of them extend the sealed `Noosh24Exception`, so a `switch` over `ApiTimeoutException()`, `ApiConnectionException()` and `ApiException()` is exhaustive. A blank API key or id, a bad `sort`/`where` type or an invalid `Where` value throws `ArgumentError`.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504`, and on network errors and timeouts, the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ... up to 8 s) and tries again, up to `maxRetries` times. It never waits more than 60 seconds; a longer `Retry-After` is thrown to you as a `RateLimitException`. Reads, cancels and creates with an `externalRef` are retried; a create without an `externalRef` is not.

## Development

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

The models in `lib/src/models.dart` are generated from the shared table in `tools/gen_models.py`:

```bash
python3 ../tools/gen_dart.py && dart format lib/src/models.dart
```

## License

MIT
