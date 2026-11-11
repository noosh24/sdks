# Noosh24 Open API for Node.js

Official Node.js and TypeScript client for the [Noosh24 Open API](https://developer.noosh24.com): read a venue's menu, reservations, orders, payments, tables, customers, loyalty, stock and reviews, and create or cancel reservations.

- Node.js 22 or newer (tested on 22, 24 and 26; uses the built-in `fetch`). No runtime dependencies.
- ESM and CommonJS, with TypeScript types for every response.
- API reference: https://developer.noosh24.com/reference

## Install

```bash
npm install @noosh24/open-api
```

## Quick start

```ts
import { Noosh24, where } from '@noosh24/open-api';

const noosh = new Noosh24(process.env.NOOSH24_API_KEY!);

const me = await noosh.whoami();
console.log(me.restaurant.name, me.key.scopes);

const page = await noosh.menu.listProducts({
  where: where().eq('category', 'Salads').eq('available', true),
  sort: 'price desc',
  limit: 50,
});
for (const product of page.items) {
  console.log(product.name, product.price);
}
console.log(`${page.total} products match`);
```

CommonJS works the same way: `const { Noosh24 } = require('@noosh24/open-api');`.

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser or a mobile app.

## Options

```ts
const noosh = new Noosh24('nsk_...', {
  baseUrl: 'https://open-api.noosh24.com/v1',
  timeout: 30_000,
  maxRetries: 2,
  userAgent: 'acme-pos/2.1',
});
```

`timeout` is in milliseconds. `fetch` takes your own fetch implementation (for a proxy agent, or for tests).

## Resources

| Group | Methods |
| --- | --- |
| `whoami()` | the venue, the key's scopes and the venue's modules |
| `menu` | `listCategories()`, `listProducts()`, `iterateProducts()`, `getProduct(id, { expand })`, `getStopList()` |
| `reservations` | `list()`, `iterate()`, `get(id)`, `availability(date, time, guests?)`, `create({...})`, `cancel(id)` |
| `orders` | `list()`, `iterate()`, `get(id)`, `listBills()`, `iterateBills()`, `getBill(id)` |
| `payments` | `list()`, `iterate()`, `get(id)`, `zReport(date?)` |
| `tables` | `list()`, `listHalls()` |
| `customers` | `list()`, `iterate()`, `get(id)` |
| `loyalty` | `getProgram()`, `listCards()`, `iterateCards()` |
| `stock` | `listIngredients()`, `iterateIngredients()`, `listMoves()`, `iterateMoves()`, `listStores()` |
| `reviews` | `list()`, `iterate()` |

Responses are plain JSON objects typed by interfaces (`Product`, `Reservation`, `Order`, ...) named as in the API. Timestamps are UTC RFC 3339 strings (`new Date(reservation.startsAt)`), money is a number in AZN.

## Lists, filters and pages

List methods take `limit`, `offset`, `sort`, `where` and, for products, `expand`. They return a `Page<T>`: `{ items, total, limit, offset, hasMore, nextOffset }`.

```ts
const orders = await noosh.orders.list({
  where: "status = 'served' AND createdAt >= '2026-11-01'",
  sort: ['createdAt desc'],
  limit: 100,
});
```

`where` is AND only. Build it with `where()` so strings and dates are quoted correctly:

```ts
const filter = where()
  .eq('status', 'confirmed')
  .gte('startsAt', new Date('2026-11-20T00:00:00+04:00'))
  .in('zone', ['Terrace', "Chef's table"]);
```

The `iterate*()` methods are async iterators that walk every page and fetch the next page only when you reach it:

```ts
for await (const payment of noosh.payments.iterate({ where: "createdAt >= '2026-11-01'" })) {
  // ...
}
```

`offset` stops at 10000. For bigger exports, narrow `where` by date and walk one window at a time.

## Reservations

```ts
import { TableTakenError } from '@noosh24/open-api';

const free = await noosh.reservations.availability('2026-11-20', '19:30', 4);

try {
  const { reservation, created } = await noosh.reservations.create({
    date: '2026-11-20',
    time: '19:30',
    guests: 4,
    guestName: 'Aysel Məmmədova',
    phone: '+994501234567',
    tableId: free.tables[0].id,
    externalRef: 'acme-booking-991',
  });
  console.log(reservation.code, created ? 'created' : 'already existed');
  await noosh.reservations.cancel(reservation.id);
} catch (error) {
  if (error instanceof TableTakenError) {
    // someone took the table first
  } else {
    throw error;
  }
}
```

A booking lands as `pending` and the venue confirms it. Always send `externalRef` (your own booking id): sending the same `externalRef` again returns the booking that already exists instead of making a second one, so a create is safe to retry. The client retries a create only when it carries an `externalRef`. You can cancel only bookings your key created.

## Errors

Every API error is a subclass of `APIError` with `status`, `code` (the API's `error` field), `message` and `headers`. Branch on the class or on `code`, not on the message.

| `code` | Error | Parent |
| --- | --- | --- |
| `validation_error` | `ValidationError` | `APIError` |
| `no_api_key` | `NoApiKeyError` | `AuthenticationError` |
| `invalid_api_key` | `InvalidApiKeyError` | `AuthenticationError` |
| `insufficient_scope` | `InsufficientScopeError` | `PermissionDeniedError` |
| `module_not_enabled` | `ModuleNotEnabledError` | `PermissionDeniedError` |
| `venue_suspended` | `VenueSuspendedError` | `PermissionDeniedError` |
| `not_your_reservation` | `NotYourReservationError` | `PermissionDeniedError` |
| `not_found` | `NotFoundError` | `APIError` |
| `table_not_found` | `TableNotFoundError` | `NotFoundError` |
| `table_taken` | `TableTakenError` | `ConflictError` |
| `cannot_cancel` | `CannotCancelError` | `ConflictError` |
| `outside_hours`, `in_the_past`, `table_too_small` | `OutsideHoursError`, `InThePastError`, `TableTooSmallError` | `UnprocessableError` |
| `rate_limit_exceeded` | `RateLimitError` (`retryAfter`) | `APIError` |
| `temporarily_unavailable` | `TemporarilyUnavailableError` | `ServerError` |

A network failure throws `APIConnectionError`; a timeout throws `APITimeoutError`. All of them extend `Noosh24Error`.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504` the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ...) and tries again, up to `maxRetries` times. It never waits more than 60 seconds; a longer `Retry-After` is thrown to you as a `RateLimitError`. Reads, cancels and creates with an `externalRef` are retried; a create without an `externalRef` is not.

## Development

```bash
npm install
npm test
npm run build
```

## License

MIT
