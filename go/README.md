<div align="center">

<a href="https://developer.noosh24.com"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup-on-dark.png"><img src="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup-on-light.png" alt="Noosh24" width="260"></picture></a>

# Noosh24 Open API for Go

**The official Go client for the [Noosh24 Open API](https://developer.noosh24.com).**<br>
Menu, reservations, orders and bills, payments and the Z-report, tables, customers, loyalty, stock and reviews of a Noosh24 venue, plus creating and cancelling reservations.

<a href="https://github.com/noosh24/sdks/actions/workflows/go.yml"><img src="https://github.com/noosh24/sdks/actions/workflows/go.yml/badge.svg" alt="CI"></a> <img src="https://img.shields.io/badge/Go-1.26%2B-00ADD8?logo=go&logoColor=white" alt="Go 1.26+"> <img src="https://img.shields.io/badge/Go%20modules-github.com%2Fnoosh24%2Fnoosh24--go-DC4A38" alt="Go modules"> <a href="https://github.com/noosh24/sdks/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>

[Developer site](https://developer.noosh24.com) · [API reference](https://developer.noosh24.com/reference) · [All SDKs](https://github.com/noosh24/sdks) · [Report an issue](https://github.com/noosh24/sdks/issues)

</div>

> [!IMPORTANT]
> **Keep the API key on your server.** A key belongs to one venue and opens its data: guests' phone numbers, payments, and writing reservations. Never put it in a browser, a mobile app or a public repository.

**Contents:** [Requirements](#requirements) · [Install](#install) · [Quick start](#quick-start) · [Options](#options) · [Resources](#resources) · [Lists, filters and pages](#lists-filters-and-pages) · [Reservations](#reservations) · [Errors](#errors) · [Retries and rate limits](#retries-and-rate-limits) · [Development](#development) · [License](#license)

## Requirements

- Go 1.26 or newer (tested on 1.26 and 1.27). Standard library only, no dependencies.
- Typed structs for every response, `iter.Seq2` iterators for every list.

## Install

```bash
go get github.com/noosh24/noosh24-go
```

```go
import "github.com/noosh24/noosh24-go"
```

The package name is `noosh24`.

## Quick start

```go
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/noosh24/noosh24-go"
)

func main() {
	ctx := context.Background()
	client, err := noosh24.NewClient(os.Getenv("NOOSH24_API_KEY"))
	if err != nil {
		log.Fatal(err)
	}

	me, err := client.Whoami(ctx)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(me.Restaurant.Name, me.Key.Scopes)

	page, err := client.Menu.ListProducts(ctx, &noosh24.ListParams{
		Where: noosh24.NewWhere().Eq("category", "Salads").Eq("available", true),
		Sort:  []string{"price desc"},
		Limit: 50,
	})
	if err != nil {
		log.Fatal(err)
	}
	for _, product := range page.Items {
		fmt.Println(product.Name, product.Price)
	}
	fmt.Println(page.Total, "products match")
}
```

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser or a mobile app.

## Options

```go
client, err := noosh24.NewClient("nsk_...",
	noosh24.WithBaseURL("https://open-api.noosh24.com/v1"),
	noosh24.WithTimeout(30*time.Second),
	noosh24.WithMaxRetries(2),
	noosh24.WithUserAgent("acme-pos/2.1"),
	noosh24.WithHTTPClient(&http.Client{Transport: myTransport}),
)
```

`WithTimeout` bounds each attempt (default 30 s; `0` leaves only your context's deadline). `WithHTTPClient` takes your own `*http.Client` (proxies, custom TLS, tests). Every method takes a `context.Context` first; cancelling it stops the request and any retry wait. An empty key or a base URL that is not absolute makes `NewClient` return an error that matches `noosh24.ErrInvalidArgument`.

## Resources

| Group | Methods |
| --- | --- |
| `Whoami(ctx)` | the venue, the key's scopes and the venue's modules |
| `Menu` | `ListCategories(ctx)`, `ListProducts(ctx, params)`, `IterateProducts(ctx, params)`, `GetProduct(ctx, id, expand...)`, `GetStopList(ctx)` |
| `Reservations` | `List(ctx, params)`, `Iterate(ctx, params)`, `Get(ctx, id)`, `Availability(ctx, date, time, guests)`, `Create(ctx, *NewReservation)`, `Cancel(ctx, id)` |
| `Orders` | `List(ctx, params)`, `Iterate(ctx, params)`, `Get(ctx, id)`, `ListBills(ctx, params)`, `IterateBills(ctx, params)`, `GetBill(ctx, id)` |
| `Payments` | `List(ctx, params)`, `Iterate(ctx, params)`, `Get(ctx, id)`, `ZReport(ctx, date)` |
| `Tables` | `List(ctx)`, `ListHalls(ctx)` |
| `Customers` | `List(ctx, params)`, `Iterate(ctx, params)`, `Get(ctx, id)` |
| `Loyalty` | `GetProgram(ctx)`, `ListCards(ctx, params)`, `IterateCards(ctx, params)` |
| `Stock` | `ListIngredients(ctx, params)`, `IterateIngredients(ctx, params)`, `ListMoves(ctx, params)`, `IterateMoves(ctx, params)`, `ListStores(ctx)` |
| `Reviews` | `List(ctx, params)`, `Iterate(ctx, params)` |

Responses are structs (`Product`, `Reservation`, `Order`, ...) with Go field names: `product.PrepMinutes`, `reservation.StartsAt`. Fields the API may send as `null` are pointers (`product.VatRate *float64`, `reservation.DecidedAt *time.Time`), nested objects are pointers, and enum fields have typed constants (`noosh24.ReservationStatusConfirmed`, `noosh24.PaymentMethodCard`). Timestamps are `time.Time` in UTC with full nanosecond precision, money is `float64` in AZN. `model.RawJSON` holds the JSON as the API sent it, including fields this version of the SDK does not know yet. `ZReport` is a free-form `map[string]any`.

## Lists, filters and pages

List methods take `*noosh24.ListParams` (or `nil`) with `Limit`, `Offset`, `Sort`, `Where` and, for products only, `Expand` (`noosh24.ExpandModifierGroups`, `noosh24.ExpandTranslations`). They return a `*noosh24.Page[T]` with `Items`, `Total`, `Limit`, `Offset`, `HasMore()` and `NextOffset()`.

```go
orders, err := client.Orders.List(ctx, &noosh24.ListParams{
	Where: noosh24.RawWhere("status = 'served' AND createdAt >= '2026-11-01'"),
	Sort:  []string{"createdAt desc"},
	Limit: 100,
})
```

`Where` is AND only, and field names are the API's camelCase names. Build it with `noosh24.NewWhere()` so strings and dates are quoted correctly; `noosh24.RawWhere` passes a string through as is:

```go
baku := time.FixedZone("Baku", 4*60*60)
condition := noosh24.NewWhere().
	Eq("status", "confirmed").
	Gte("startsAt", time.Date(2026, 11, 20, 0, 0, 0, 0, baku)).
	Lt("visitedOn", noosh24.NewDate(2026, time.November, 21)).
	In("zone", "Terrace", "Chef's table")
```

The builder takes strings, numbers, booleans, `time.Time` and `noosh24.Date`. A bad field name, an empty `In`, `NaN` or `nil` is kept in `condition.Err()`, and the list call returns it (matching `noosh24.ErrInvalidArgument`) without sending a request. `condition.Build()` returns the text and that error.

The `Iterate*` methods walk every page and fetch the next page only when the loop reaches it:

```go
for payment, err := range client.Payments.Iterate(ctx, &noosh24.ListParams{Where: noosh24.RawWhere("createdAt >= '2026-11-01'")}) {
	if err != nil {
		return err
	}
	fmt.Println(payment.ID, payment.Amount)
}
```

They ask for the largest page each endpoint allows (100, or 50 for bills and for products with `Expand`) unless you set `Limit`. `Offset` stops at 10000. For bigger exports, narrow `Where` by date and walk one window at a time.

## Reservations

```go
free, err := client.Reservations.Availability(ctx, "2026-11-20", "19:30", 4)
if err != nil {
	return err
}

result, err := client.Reservations.Create(ctx, &noosh24.NewReservation{
	Date:        "2026-11-20",
	Time:        "19:30",
	Guests:      4,
	GuestName:   "Aysel Məmmədova",
	Phone:       "+994501234567",
	TableID:     free.Tables[0].ID,
	ChildChair:  noosh24.Bool(true),
	PreOrder:    []noosh24.PreOrderLine{{ItemID: "0b6f3c1e", Qty: 2}},
	ExternalRef: "acme-booking-991",
})
switch {
case noosh24.IsTableTaken(err):
	return errTryAnotherTable
case err != nil:
	return err
}

fmt.Println(result.Reservation.Code, result.Created)
_, err = client.Reservations.Cancel(ctx, result.Reservation.ID)
```

A booking lands as `pending` and the venue confirms it. Always send `ExternalRef` (your own booking id): sending the same `ExternalRef` again returns the booking that already exists instead of making a second one (`result.Created` is then `false`), so a create is safe to retry. The client retries a create only when it carries an `ExternalRef`. You can cancel only bookings your key created. `Availability` leaves `guests` out when it is `0`; `ZReport` leaves `date` out when it is `""`.

## Errors

Every API error is a `*noosh24.APIError` with `Status`, `Code` (the API's `error` field), `Message`, `Kind`, `Header` and `Body`. Branch on the helper predicates, on `Kind` or on `Code`, not on the message. The predicates follow `errors.As`, so they work on wrapped errors, and a parent predicate matches its children (`IsConflict` is true for `table_taken`).

| `code` | Constant | `Kind` | Predicate | Parent |
| --- | --- | --- | --- | --- |
| `validation_error` | `CodeValidationError` | `KindValidation` | `IsValidation` | `APIError` |
| `no_api_key` | `CodeNoAPIKey` | `KindNoAPIKey` | `IsNoAPIKey` | `IsAuthentication` |
| `invalid_api_key` | `CodeInvalidAPIKey` | `KindInvalidAPIKey` | `IsInvalidAPIKey` | `IsAuthentication` |
| `insufficient_scope` | `CodeInsufficientScope` | `KindInsufficientScope` | `IsInsufficientScope` | `IsPermissionDenied` |
| `module_not_enabled` | `CodeModuleNotEnabled` | `KindModuleNotEnabled` | `IsModuleNotEnabled` | `IsPermissionDenied` |
| `venue_suspended` | `CodeVenueSuspended` | `KindVenueSuspended` | `IsVenueSuspended` | `IsPermissionDenied` |
| `not_your_reservation` | `CodeNotYourReservation` | `KindNotYourReservation` | `IsNotYourReservation` | `IsPermissionDenied` |
| `not_found` | `CodeNotFound` | `KindNotFound` | `IsNotFound` | `APIError` |
| `table_not_found` | `CodeTableNotFound` | `KindTableNotFound` | `IsTableNotFound` | `IsNotFound` |
| `table_taken` | `CodeTableTaken` | `KindTableTaken` | `IsTableTaken` | `IsConflict` |
| `cannot_cancel` | `CodeCannotCancel` | `KindCannotCancel` | `IsCannotCancel` | `IsConflict` |
| `outside_hours`, `in_the_past`, `table_too_small` | `CodeOutsideHours`, `CodeInThePast`, `CodeTableTooSmall` | `KindOutsideHours`, `KindInThePast`, `KindTableTooSmall` | `IsOutsideHours`, `IsInThePast`, `IsTableTooSmall` | `IsUnprocessable` |
| `rate_limit_exceeded` | `CodeRateLimitExceeded` | `KindRateLimit` | `IsRateLimited` | `APIError` |
| `temporarily_unavailable` | `CodeTemporarilyUnavailable` | `KindTemporarilyUnavailable` | `IsTemporarilyUnavailable` | `IsServerError` |

An unknown code falls back to its status (`403` is `KindPermissionDenied`, `409` is `KindConflict`, any `5xx` is `KindServer`), and anything else is `KindAPI`. `Kind.String()` gives the class names the other Noosh24 SDKs use (`"TableTakenError"`), and `Kind.Is(noosh24.KindConflict)` walks the parents.

```go
if apiErr, ok := noosh24.AsAPIError(err); ok && noosh24.IsRateLimited(err) {
	wait, _ := apiErr.RetryAfter()
	log.Printf("rate limited, retry in %s", wait)
}
```

A network failure returns a `*noosh24.ConnectionError` that matches `errors.Is(err, noosh24.ErrConnection)`; a timeout also matches `noosh24.ErrTimeout`. The underlying transport error stays reachable with `errors.Is`/`errors.As`.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504`, and on network errors and timeouts, the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ... up to 8 s) and tries again, up to `WithMaxRetries` times. It never waits more than 60 seconds; a longer `Retry-After` is returned to you as a rate-limit error with `RetryAfter()` set. Reads, cancels and creates with an `ExternalRef` are retried; a create without an `ExternalRef` is not.

## Development

```bash
go vet ./...
gofmt -l .
go test -race ./...
go run honnef.co/go/tools/cmd/staticcheck@latest ./...
```

The models in `models.go` are generated from the table in `tools/gen_models.py`: run `python3 tools/gen_go.py` from the repository root after a spec change.

## License

MIT
