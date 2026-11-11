# Noosh24 Open API for PHP

Official PHP client for the [Noosh24 Open API](https://developer.noosh24.com): read a venue's menu, reservations, orders, payments, tables, customers, loyalty, stock and reviews, and create or cancel reservations.

- PHP 7.4 or newer, `ext-curl`, `ext-json`. No other dependencies.
- API reference: https://developer.noosh24.com/reference

## Install

```bash
composer require noosh24/open-api
```

## Quick start

```php
<?php

require 'vendor/autoload.php';

use Noosh24\OpenApi\Client;
use Noosh24\OpenApi\Where;

$noosh = new Client(getenv('NOOSH24_API_KEY'));

$me = $noosh->whoami();
echo $me->restaurant->name, PHP_EOL;
print_r($me->key->scopes);

$page = $noosh->menu->listProducts([
    'where' => Where::create()->eq('category', 'Salads')->eq('available', true),
    'sort' => 'price desc',
    'limit' => 50,
]);
foreach ($page as $product) {
    printf("%s  %.2f AZN\n", $product->name, $product->price);
}
echo $page->total, ' products match', PHP_EOL;
```

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser or a mobile app.

## Options

```php
$noosh = new Client('nsk_...', [
    'baseUrl' => 'https://open-api.noosh24.com/v1',
    'timeout' => 30,
    'maxRetries' => 2,
    'userAgent' => 'acme-pos/2.1',
]);
```

`timeout` is in seconds. `transport` takes your own `Noosh24\OpenApi\Http\Transport` if you do not want cURL.

## Resources

| Group | Methods |
| --- | --- |
| `whoami()` | the venue, the key's scopes and the venue's modules |
| `menu` | `listCategories()`, `listProducts()`, `iterateProducts()`, `getProduct($id, $expand)`, `getStopList()` |
| `reservations` | `list()`, `iterate()`, `get($id)`, `availability($date, $time, $guests)`, `create([...])`, `cancel($id)` |
| `orders` | `list()`, `iterate()`, `get($id)`, `listBills()`, `iterateBills()`, `getBill($id)` |
| `payments` | `list()`, `iterate()`, `get($id)`, `zReport($date)` |
| `tables` | `list()`, `listHalls()` |
| `customers` | `list()`, `iterate()`, `get($id)` |
| `loyalty` | `getProgram()`, `listCards()`, `iterateCards()` |
| `stock` | `listIngredients()`, `iterateIngredients()`, `listMoves()`, `iterateMoves()`, `listStores()` |
| `reviews` | `list()`, `iterate()` |

Every response is a typed model (`Product`, `Reservation`, `Order`, ...) with public properties named as in the API. Timestamps are `DateTimeImmutable` in UTC, money is `float` in AZN. `$model->toArray()` gives the raw JSON, including fields this version of the SDK does not know yet.

## Lists, filters and pages

List methods take `limit`, `offset`, `sort`, `where` and, for products, `expand`. They return a `Page` with `items`, `total`, `limit`, `offset` and `hasMore()`.

```php
$page = $noosh->orders->list([
    'where' => "status = 'served' AND createdAt >= '2026-11-01'",
    'sort' => ['createdAt desc'],
    'limit' => 100,
    'offset' => 0,
]);
```

`where` is AND only. Build it with `Where` so strings and dates are quoted correctly:

```php
$where = Where::create()
    ->eq('status', 'confirmed')
    ->gte('startsAt', new DateTimeImmutable('2026-11-20T00:00:00+04:00'))
    ->in('zone', ['Terrace', "Chef's table"]);
```

The `iterate*()` methods walk every page for you and fetch the next page only when you reach it:

```php
foreach ($noosh->payments->iterate(['where' => "createdAt >= '2026-11-01'"]) as $payment) {
    // ...
}
```

`offset` stops at 10000. For bigger exports, narrow `where` by date and walk one window at a time.

## Reservations

```php
use Noosh24\OpenApi\Exception\TableTakenException;

$free = $noosh->reservations->availability('2026-11-20', '19:30', 4);

try {
    $result = $noosh->reservations->create([
        'date' => '2026-11-20',
        'time' => '19:30',
        'guests' => 4,
        'guestName' => 'Aysel Məmmədova',
        'phone' => '+994501234567',
        'tableId' => $free->tables[0]->id,
        'externalRef' => 'acme-booking-991',
    ]);
} catch (TableTakenException $e) {
    // someone took the table first
}

echo $result->reservation->code, $result->created ? ' created' : ' already existed', PHP_EOL;

$noosh->reservations->cancel($result->reservation->id);
```

A booking lands as `pending` and the venue confirms it. Always send `externalRef` (your own booking id): sending the same `externalRef` again returns the booking that already exists instead of making a second one, so a create is safe to retry. The client retries a create only when it carries an `externalRef`. You can cancel only bookings your key created.

## Errors

Every API error throws a subclass of `Noosh24\OpenApi\Exception\ApiException` with `getStatus()`, `getErrorCode()` (the API's `error` field), `getMessage()` and `getHeaders()`. Branch on the class or on `getErrorCode()`, not on the message.

| `error` | Exception | Parent |
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
| `rate_limit_exceeded` | `RateLimitException` (`getRetryAfter()`) | `ApiException` |
| `temporarily_unavailable` | `TemporarilyUnavailableException` | `ServerException` |

A network failure or timeout throws `ConnectionException`. All of them implement `Noosh24Exception`.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504` the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ...) and tries again, up to `maxRetries` times. It never waits more than 60 seconds; a longer `Retry-After` is thrown to you as a `RateLimitException`. Reads, cancels and creates with an `externalRef` are retried; a create without an `externalRef` is not.

## Development

```bash
composer install
composer test
```

## License

MIT
