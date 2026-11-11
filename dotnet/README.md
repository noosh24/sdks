<div align="center">

<a href="https://developer.noosh24.com"><img src="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup.svg" alt="Noosh24" width="260"></a>

# Noosh24 Open API for C# and .NET

**The official C# and .NET client for the [Noosh24 Open API](https://developer.noosh24.com).**<br>
Menu, reservations, orders and bills, payments and the Z-report, tables, customers, loyalty, stock and reviews of a Noosh24 venue, plus creating and cancelling reservations.

<a href="https://github.com/noosh24/sdks/actions/workflows/dotnet.yml"><img src="https://github.com/noosh24/sdks/actions/workflows/dotnet.yml/badge.svg" alt="CI"></a> <img src="https://img.shields.io/badge/.NET-10%2B-512BD4?logo=dotnet&logoColor=white" alt=".NET 10+"> <img src="https://img.shields.io/badge/NuGet-Noosh24.OpenApi-DC4A38" alt="NuGet"> <a href="https://github.com/noosh24/sdks/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>

[Developer site](https://developer.noosh24.com) · [API reference](https://developer.noosh24.com/reference) · [All SDKs](https://github.com/noosh24/sdks) · [Report an issue](https://github.com/noosh24/sdks/issues)

</div>

> [!IMPORTANT]
> **Keep the API key on your server.** A key belongs to one venue and opens its data: guests' phone numbers, payments, and writing reservations. Never put it in a browser, a mobile app or a public repository.

**Contents:** [Requirements](#requirements) · [Install](#install) · [Quick start](#quick-start) · [Options](#options) · [Resources](#resources) · [Lists, filters and pages](#lists-filters-and-pages) · [Reservations](#reservations) · [Errors](#errors) · [Retries and rate limits](#retries-and-rate-limits) · [Development](#development) · [License](#license)

## Requirements

- .NET 10 or newer (packaged for `net10.0` and `net11.0`, tested on 10.0 and 11.0). No dependencies outside the base class library.
- Async-only, with a `CancellationToken` on every call. `System.Text.Json` source generation, so the package is trim and Native AOT safe.

## Install

```bash
dotnet add package Noosh24.OpenApi
```

## Quick start

```csharp
using Noosh24.OpenApi;

using var noosh = new Noosh24Client(Environment.GetEnvironmentVariable("NOOSH24_API_KEY")!);

var me = await noosh.WhoamiAsync();
Console.WriteLine($"{me.Restaurant?.Name} {string.Join(", ", me.Key?.Scopes ?? [])}");

var page = await noosh.Menu.ListProductsAsync(new ProductListOptions
{
    Where = new Where().Eq("category", "Salads").Eq("available", true),
    Sort = ["price desc"],
    Limit = 50,
});
foreach (var product in page)
{
    Console.WriteLine($"{product.Name} {product.Price}");
}
Console.WriteLine($"{page.Total} products match");
```

The key belongs to one venue, so there is no venue parameter anywhere. Keys are issued in the Noosh24 panel; keep them on your server, never in a browser or a mobile app.

## Options

```csharp
using var noosh = new Noosh24Client("nsk_...", new Noosh24ClientOptions
{
    BaseUrl = "https://open-api.noosh24.com/v1",
    Timeout = TimeSpan.FromSeconds(30),
    MaxRetries = 2,
    UserAgent = "acme-pos/2.1",
});
```

`Timeout` applies to each attempt. `Delay` replaces the wait between retries (tests use it to skip the wait). To bring your own `HttpClient` (from `IHttpClientFactory`, with a proxy, custom TLS or a test `HttpMessageHandler`), pass it as the second argument; the client then leaves its lifetime to you:

```csharp
var noosh = new Noosh24Client("nsk_...", httpClientFactory.CreateClient("noosh24"), new Noosh24ClientOptions { MaxRetries = 3 });
```

`Noosh24Client` is thread safe and meant to be kept for the life of the app. Dispose it to release the connections it opened itself.

## Resources

| Group | Methods |
| --- | --- |
| `WhoamiAsync()` | the venue, the key's scopes and the venue's modules |
| `Menu` | `ListCategoriesAsync()`, `ListProductsAsync()`, `IterateProductsAsync()`, `GetProductAsync(id, expand)`, `GetStopListAsync()` |
| `Reservations` | `ListAsync()`, `IterateAsync()`, `GetAsync(id)`, `AvailabilityAsync(date, time, guests)`, `CreateAsync(NewReservation)`, `CancelAsync(id)` |
| `Orders` | `ListAsync()`, `IterateAsync()`, `GetAsync(id)`, `ListBillsAsync()`, `IterateBillsAsync()`, `GetBillAsync(id)` |
| `Payments` | `ListAsync()`, `IterateAsync()`, `GetAsync(id)`, `ZReportAsync(date)` |
| `Tables` | `ListAsync()`, `ListHallsAsync()` |
| `Customers` | `ListAsync()`, `IterateAsync()`, `GetAsync(id)` |
| `Loyalty` | `GetProgramAsync()`, `ListCardsAsync()`, `IterateCardsAsync()` |
| `Stock` | `ListIngredientsAsync()`, `IterateIngredientsAsync()`, `ListMovesAsync()`, `IterateMovesAsync()`, `ListStoresAsync()` |
| `Reviews` | `ListAsync()`, `IterateAsync()` |

Responses are immutable records (`Product`, `Reservation`, `Order`, ...) named as in the API, with PascalCase properties: `product.PrepMinutes`, `reservation.StartsAt`. Every property is nullable, so a field the API leaves out is `null` rather than an error. Timestamps are `DateTimeOffset` in UTC (the API's nanoseconds are cut to .NET's 100 ns ticks), money is `double` in AZN. `ExtensionData` holds the JSON fields this version of the SDK does not know yet. Status values are plain strings, with constants for the known ones: `ReservationStatus.Pending`, `OrderKind.Delivery`, `PaymentMethod.Card`. `ZReportAsync` returns the report as `IReadOnlyDictionary<string, JsonElement>`.

## Lists, filters and pages

List methods take a `ListOptions` (`ProductListOptions` for products, which adds `Expand`) with `Limit`, `Offset`, `Sort` and `Where`. They return a `Page<T>` with `Items`, `Total`, `Limit`, `Offset`, `HasMore` and `NextOffset`; a page is itself an `IReadOnlyList<T>`.

```csharp
var orders = await noosh.Orders.ListAsync(new ListOptions
{
    Where = "status = 'served' AND createdAt >= '2026-11-01'",
    Sort = ["createdAt desc"],
    Limit = 100,
});
```

`Where` is AND only, and field names are the API's camelCase names. A plain string converts to a `Where`; build it with the methods `Eq`, `Ne`, `Gt`, `Gte`, `Lt`, `Lte` and `In` so strings and dates are quoted correctly. Values can be strings, numbers, booleans, `DateTimeOffset`, `DateTime` (UTC or local, not unspecified) and `DateOnly`:

```csharp
var filter = new Where()
    .Eq("status", ReservationStatus.Confirmed)
    .Gte("startsAt", new DateTimeOffset(2026, 11, 20, 0, 0, 0, TimeSpan.FromHours(4)))
    .In("zone", "Terrace", "Chef's table");
```

Products take `Expand = [ProductExpand.ModifierGroups, ProductExpand.Translations]` on lists and `GetProductAsync(id, [ProductExpand.Translations])`.

The `Iterate*Async()` methods return an `IAsyncEnumerable<T>` that walks every page and fetches the next page only when you reach it:

```csharp
await foreach (var payment in noosh.Payments.IterateAsync(new ListOptions { Where = "createdAt >= '2026-11-01'" }, cancellationToken))
{
}
```

`Offset` stops at 10000. For bigger exports, narrow `Where` by date and walk one window at a time.

## Reservations

```csharp
var free = await noosh.Reservations.AvailabilityAsync(new DateOnly(2026, 11, 20), new TimeOnly(19, 30), guests: 4);

try
{
    var result = await noosh.Reservations.CreateAsync(new NewReservation
    {
        Date = new DateOnly(2026, 11, 20),
        Time = new TimeOnly(19, 30),
        Guests = 4,
        GuestName = "Aysel Məmmədova",
        Phone = "+994501234567",
        TableId = free.Tables?[0].Id,
        PreOrder = [new PreOrderLine("0b6f3c1e", 2)],
        ExternalRef = "acme-booking-991",
    });
    Console.WriteLine($"{result.Reservation.Code} {(result.Created ? "created" : "already existed")}");
    await noosh.Reservations.CancelAsync(result.Reservation.Id!);
}
catch (TableTakenException)
{
}
```

A booking lands as `pending` and the venue confirms it. Always send `ExternalRef` (your own booking id): sending the same `ExternalRef` again returns the booking that already exists instead of making a second one, so a create is safe to retry. The client retries a create only when it carries an `ExternalRef`. You can cancel only bookings your key created.

## Errors

Every API error is a subclass of `ApiException` with `Status`, `Code` (the API's `error` field), `Message`, `Headers` (lower-cased names) and `Body`. Branch on the type or on `Code`, not on the message.

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
| `rate_limit_exceeded` | `RateLimitException` (`RetryAfter`, seconds) | `ApiException` |
| `temporarily_unavailable` | `TemporarilyUnavailableException` | `ServerException` |

An unknown code falls back to the class of its HTTP status (`AuthenticationException` for 401, `ServerException` for any 5xx). A network failure throws `ApiConnectionException`; a timeout throws `ApiTimeoutException`, which extends it. All of them extend `Noosh24Exception`. Cancelling your own `CancellationToken` throws the usual `OperationCanceledException`. Bad arguments (an empty key or id, a bad `Where` field or value) throw `ArgumentException`.

## Retries and rate limits

A key gets 600 requests a minute. On `429` and `502`/`503`/`504`, on network failures and on timeouts the client waits (`Retry-After` when the API sends it, otherwise 0.5 s, 1 s, 2 s ...) and tries again, up to `MaxRetries` times. It never waits more than 60 seconds; a longer `Retry-After` is thrown to you as a `RateLimitException`. Reads, cancels and creates with an `ExternalRef` are retried; a create without an `ExternalRef` is not.

## Development

```bash
dotnet test
```

The models (`Models.cs`, `Enums.cs`, `Noosh24JsonContext.cs`) are generated from the table in `tools/gen_models.py`; after a spec change run `python3 tools/gen_dotnet.py` from the repository root. With the .NET 10 SDK the projects build for `net10.0`; with the .NET 11 SDK they build for `net10.0` and `net11.0`, so pack releases with the .NET 11 SDK:

```bash
dotnet pack src/Noosh24.OpenApi -c Release -o artifacts
dotnet nuget push artifacts/Noosh24.OpenApi.0.1.0.nupkg --api-key "$NUGET_API_KEY" --source https://api.nuget.org/v3/index.json
```

## License

MIT
