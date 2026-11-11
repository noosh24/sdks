<div align="center">

<a href="https://developer.noosh24.com"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup-on-dark.png"><img src="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup-on-light.png" alt="Noosh24" width="260"></picture></a>

# Noosh24 Open API for Ruby

**The official Ruby client for the [Noosh24 Open API](https://developer.noosh24.com).**<br>
Menu, reservations, orders and bills, payments and the Z-report, tables, customers, loyalty, stock and reviews of a Noosh24 venue, plus creating and cancelling reservations.

<a href="https://github.com/noosh24/sdks/actions/workflows/ruby.yml"><img src="https://github.com/noosh24/sdks/actions/workflows/ruby.yml/badge.svg" alt="CI"></a> <img src="https://img.shields.io/badge/Ruby-3.3%2B-CC342D?logo=ruby&logoColor=white" alt="Ruby 3.3+"> <img src="https://img.shields.io/badge/RubyGems-noosh24-DC4A38" alt="RubyGems"> <a href="https://github.com/noosh24/sdks/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>

[Developer site](https://developer.noosh24.com) · [API reference](https://developer.noosh24.com/reference) · [All SDKs](https://github.com/noosh24/sdks) · [Report an issue](https://github.com/noosh24/sdks/issues)

</div>

> [!IMPORTANT]
> **Keep the API key on your server.** A key belongs to one venue and opens its data: guests' phone numbers, payments, and writing reservations. Never put it in a browser, a mobile app or a public repository.

**Contents:** [Requirements](#requirements) · [Install](#install) · [Quick start](#quick-start) · [Options](#options) · [Resources](#resources) · [Lists, filters and pages](#lists-filters-and-pages) · [Reservations](#reservations) · [Errors](#errors) · [Retries and rate limits](#retries-and-rate-limits) · [Development](#development) · [License](#license)

## Requirements

- Ruby 3.3 or newer (tested on 3.3 and 4.0). No runtime dependencies: `net/http` and `json` from the standard library.
- Frozen value objects (`Data`) for every response.

## Install

```bash
gem install noosh24
```

or in a `Gemfile`:

```ruby
gem "noosh24", "~> 0.1"
```

## Quick start

```ruby
require "noosh24"

noosh = Noosh24::Client.new(ENV.fetch("NOOSH24_API_KEY"))

me = noosh.whoami
puts me.restaurant.name, me.key.scopes.inspect

page = noosh.menu.list_products(
  where: Noosh24.where.eq("category", "Salads").eq("available", true),
  sort: "price desc",
  limit: 50
)
page.each { |product| puts "#{product.name} #{product.price}" }
puts "#{page.total} products match"
```

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser or a mobile app.

## Options

```ruby
noosh = Noosh24::Client.new(
  "nsk_...",
  base_url: "https://open-api.noosh24.com/v1",
  timeout: 30,
  max_retries: 2,
  user_agent: "acme-pos/2.1"
)
```

`timeout` is in seconds and applies to connecting, writing and reading. `transport:` takes any object that responds to `call(request)` with a `Noosh24::Request` (`http_method`, `url`, `headers`, `body`, `timeout`) and returns a `Noosh24::Response` (`status`, `headers`, `body`); use it for proxies, custom TLS or tests. `sleep:` takes a callable that receives the seconds to wait between retries.

## Resources

| Group | Methods |
| --- | --- |
| `whoami` | the venue, the key's scopes and the venue's modules |
| `menu` | `list_categories`, `list_products`, `iterate_products`, `get_product(id, expand:)`, `get_stop_list` |
| `reservations` | `list`, `iterate`, `get(id)`, `availability(date, time, guests:)`, `create(...)`, `cancel(id)` |
| `orders` | `list`, `iterate`, `get(id)`, `list_bills`, `iterate_bills`, `get_bill(id)` |
| `payments` | `list`, `iterate`, `get(id)`, `z_report(date = nil)` |
| `tables` | `list`, `list_halls` |
| `customers` | `list`, `iterate`, `get(id)` |
| `loyalty` | `get_program`, `list_cards`, `iterate_cards` |
| `stock` | `list_ingredients`, `iterate_ingredients`, `list_moves`, `iterate_moves`, `list_stores` |
| `reviews` | `list`, `iterate` |

Responses are frozen `Data` objects (`Noosh24::Product`, `Noosh24::Reservation`, `Noosh24::Order`, ...) with snake_case readers: `product.prep_minutes`, `reservation.starts_at`. Timestamps are `Time` objects in UTC (nanoseconds kept), money is `Float` in AZN. `model.raw` holds the JSON as the API sent it, including fields this version of the SDK does not know yet. `z_report` returns the report as a frozen `Hash`.

## Lists, filters and pages

List methods take `limit:`, `offset:`, `sort:`, `where:` and, for products, `expand:`. They return a `Noosh24::Page` with `items`, `total`, `limit`, `offset`, `has_more?` and `next_offset`; a page is `Enumerable`.

```ruby
orders = noosh.orders.list(
  where: "status = 'served' AND createdAt >= '2026-11-01'",
  sort: ["createdAt desc"],
  limit: 100
)
```

`where` is AND only, and field names are the API's camelCase names. Build it with `Noosh24.where` so strings and dates are quoted correctly:

```ruby
condition = Noosh24.where
                   .eq("status", "confirmed")
                   .gte("startsAt", Time.new(2026, 11, 20, 0, 0, 0, "+04:00"))
                   .in("zone", ["Terrace", "Chef's table"])
```

The builder has `eq`, `ne`, `gt`, `gte`, `lt`, `lte` and `in`, and takes strings, integers, floats, `true`/`false`, `Time` and `Date`.

The `iterate*` methods walk every page and fetch the next page only when you reach it. Without a block they return an `Enumerator`; with a block they yield each item:

```ruby
noosh.payments.iterate(where: "createdAt >= '2026-11-01'") do |payment|
  puts payment.amount
end

first_ten = noosh.customers.iterate.first(10)
```

`offset` stops at 10000. For bigger exports, narrow `where` by date and walk one window at a time.

## Reservations

```ruby
free = noosh.reservations.availability("2026-11-20", "19:30", guests: 4)

begin
  result = noosh.reservations.create(
    date: "2026-11-20",
    time: "19:30",
    guests: 4,
    guest_name: "Aysel Məmmədova",
    phone: "+994501234567",
    table_id: free.tables.first.id,
    pre_order: [Noosh24::PreOrderLine.new(item_id: "0b6f3c1e", qty: 2)],
    external_ref: "acme-booking-991"
  )
rescue Noosh24::TableTakenError
  warn "That table was just taken"
end

puts result.reservation.code, result.created? ? "created" : "already existed"
noosh.reservations.cancel(result.reservation.id)
```

`create` also takes a `Noosh24::NewReservation` (`Noosh24::NewReservation.new(date:, time:, guests:, guest_name:, phone:, ...)`), and `date` may be a `Date`. A booking lands as `pending` and the venue confirms it. Always send `external_ref` (your own booking id): sending the same `external_ref` again returns the booking that already exists instead of making a second one, so a create is safe to retry. The client retries a create only when it carries an `external_ref`. You can cancel only bookings your key created.

## Errors

Every API error is a subclass of `Noosh24::APIError` with `status`, `code` (the API's `error` field), `message`, `headers` (lower-cased names) and `body`. Branch on the class or on `code`, not on the message.

| `code` | Exception | Parent |
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
| `rate_limit_exceeded` | `RateLimitError` (`retry_after`) | `APIError` |
| `temporarily_unavailable` | `TemporarilyUnavailableError` | `ServerError` |

All classes live under `Noosh24::`. An unknown code falls back to the class for its status (`ServerError` for any 5xx). A network failure raises `APIConnectionError`; a timeout raises `APITimeoutError` (a subclass of `APIConnectionError`). All of them extend `Noosh24::Error`, which extends `StandardError`. Bad arguments (an empty key or id, a bad `where` field or value) raise `ArgumentError`.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504` the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ...) and tries again, up to `max_retries` times. It never waits more than 60 seconds; a longer `Retry-After` is raised to you as a `RateLimitError`. Reads, cancels and creates with an `external_ref` are retried; a create without an `external_ref` is not.

## Development

```bash
bundle install
bundle exec rake test
bundle exec rubocop
```

Without a local Ruby 3.3+:

```bash
docker run --rm -v "$PWD":/app -w /app ruby:3.3 sh -c 'bundle install && bundle exec rake'
docker run --rm -v "$PWD":/app -w /app ruby:4.0 sh -c 'bundle install && bundle exec rake'
```

The models in `lib/noosh24/models.rb` are generated: `python3 tools/gen_ruby.py` from the repository root.

## License

MIT
