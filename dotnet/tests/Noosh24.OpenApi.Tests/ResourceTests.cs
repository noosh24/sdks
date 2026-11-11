using System.Text;
using System.Text.Json;
using Noosh24.OpenApi;

namespace Noosh24.OpenApi.Tests;

public sealed class ResourceTests
{
    private const string Product = """
        {
          "id": "0b6f3c1e",
          "name": "Plov",
          "category": "Main",
          "description": "Saffron rice with lamb",
          "price": 14,
          "available": true,
          "popular": true,
          "position": 3,
          "prepMinutes": 20,
          "station": "",
          "vatRate": null,
          "vegetarian": false,
          "spicy": false,
          "allergens": ["gluten"],
          "discountable": true,
          "hasModifiers": true,
          "image": "https://api.noosh24.com/m/5c1d.jpg",
          "video": null,
          "modifierGroups": [
            {"id": "g1", "name": "Size", "required": true, "position": 0,
             "modifiers": [{"id": "m1", "name": "Large", "priceDelta": 2.5, "position": 0}]}
          ],
          "translations": {"en": {"name": "Pilaf", "description": "Rice"}, "ru": {"name": "Плов"}}
        }
        """;

    private const string Reservation = """
        {
          "id": "res1",
          "code": "K7Q2",
          "status": "pending",
          "source": "open_api",
          "startsAt": "2026-11-20T15:30:00Z",
          "endsAt": "2026-11-20T17:30:00.123456789Z",
          "guests": 4,
          "zone": "Terrace",
          "table": {"id": "t5", "label": "T5"},
          "guest": {"name": "Aysel", "phone": "+994501234567", "email": null},
          "specialRequest": null,
          "allergyNote": null,
          "birthday": false,
          "childChair": true,
          "depositPaid": 0,
          "preOrder": [{"productId": "p1", "name": "Plov", "price": 14.5, "qty": 2, "note": null}],
          "externalRef": "acme-991",
          "decidedAt": null,
          "createdAt": "2026-11-11T10:00:00.5Z",
          "updatedAt": "2026-11-11T10:00:00Z"
        }
        """;

    private static readonly NewReservation Booking = new()
    {
        Date = new DateOnly(2026, 11, 20),
        Time = new TimeOnly(19, 30),
        Guests = 4,
        GuestName = "Aysel Məmmədova",
        Phone = "+994501234567",
    };

    private static CancellationToken Token => TestContext.Current.CancellationToken;

    private static string Data(string json) => "{\"data\": " + json + "}";

    private static string Cancelled() => Data(Reservation.Replace("\"status\": \"pending\"", "\"status\": \"cancelled\"", StringComparison.Ordinal));

    private static async Task<List<T>> ToListAsync<T>(IAsyncEnumerable<T> source)
    {
        var list = new List<T>();
        await foreach (var item in source)
        {
            list.Add(item);
        }

        return list;
    }

    [Fact]
    public async Task ListProductsSendsListParametersAndParsesThePage()
    {
        using var h = new Harness();
        h.Http.Raw(200, Data($$"""{"items": [{{Product}}], "total": 87, "limit": 50, "offset": 50}"""));

        var result = await h.Client.Menu.ListProductsAsync(
            new ProductListOptions
            {
                Limit = 50,
                Offset = 50,
                Sort = ["category asc", "price desc"],
                Where = new Where().Eq("category", "Chef's").Gte("price", 5).Eq("available", true),
                Expand = [ProductExpand.ModifierGroups, ProductExpand.Translations],
            },
            Token);

        Assert.Equal("/v1/menu/products", h.Http.Last.Path);
        var query = h.Http.Last.Query;
        Assert.Equal(["limit", "offset", "sort", "where", "expand"], query.Keys);
        Assert.Equal(["50"], query["limit"]);
        Assert.Equal(["50"], query["offset"]);
        Assert.Equal(["category asc", "price desc"], query["sort"]);
        Assert.Equal(["category = 'Chef''s' AND price >= 5 AND available = true"], query["where"]);
        Assert.Equal(["modifierGroups", "translations"], query["expand"]);
        Assert.Contains("sort=category%20asc", h.Http.Last.Uri.Query, StringComparison.Ordinal);
        Assert.Equal((87, 50, 50, true, 1, 51), (result.Total, result.Limit, result.Offset, result.HasMore, result.Count, result.NextOffset));

        var product = Assert.Single(result);
        Assert.Equal(14.0, product.Price);
        Assert.Null(product.VatRate);
        Assert.Equal(20, product.PrepMinutes);
        Assert.Equal(["gluten"], product.Allergens!);
        Assert.Equal(2.5, product.ModifierGroups![0].Modifiers![0].PriceDelta);
        Assert.Equal("Pilaf", product.Translations!["en"].Name);
        Assert.Null(product.Translations["ru"].Description);
        Assert.Equal("Плов", product.Translations["ru"].Name);
        Assert.Null(product.ExtensionData);
    }

    [Fact]
    public async Task ListAcceptsPlainWhereAndSortString()
    {
        using var h = new Harness();
        h.Http.Json(200, Harness.Page([], 0));

        await h.Client.Orders.ListAsync(new() { Where = "status = 'served'", Sort = ["createdAt desc"] }, Token);

        var query = h.Http.Last.Query;
        Assert.Equal(["sort", "where"], query.Keys);
        Assert.Equal(["createdAt desc"], query["sort"]);
        Assert.Equal(["status = 'served'"], query["where"]);
    }

    [Fact]
    public async Task ListWithoutOptionsSendsNoQuery()
    {
        using var h = new Harness();
        h.Http.Raw(200, """{"data": {"items": [{"id": "c1"}]}}""");

        var page = await h.Client.Customers.ListAsync(cancellationToken: Token);

        Assert.Equal("https://open-api.noosh24.com/v1/customers", h.Http.Last.Url);
        Assert.Equal((1, 1, 0, false), (page.Total, page.Limit, page.Offset, page.HasMore));
    }

    [Fact]
    public async Task IteratorWalksEveryPage()
    {
        using var h = new Harness();
        h.Http.Json(200, Harness.Page([new { id = "c1" }, new { id = "c2" }], 5, 2, 0));
        h.Http.Json(200, Harness.Page([new { id = "c3" }, new { id = "c4" }], 5, 2, 2));
        h.Http.Json(200, Harness.Page([new { id = "c5" }], 5, 2, 4));

        var customers = await ToListAsync(h.Client.Customers.IterateAsync(new() { Limit = 2, Where = "createdAt >= '2026-11-01'" }, Token));

        Assert.Equal(["c1", "c2", "c3", "c4", "c5"], customers.Select(c => c.Id));
        Assert.Equal(["0", "2", "4"], h.Http.Requests.Select(r => r.Query["offset"][0]));
        Assert.Equal(["2", "2", "2"], h.Http.Requests.Select(r => r.Query["limit"][0]));
        Assert.Equal(["createdAt >= '2026-11-01'"], h.Http.Requests[2].Query["where"]);
    }

    [Fact]
    public async Task IteratorStartsAtTheGivenOffset()
    {
        using var h = new Harness();
        h.Http.Json(200, Harness.Page([new { id = "rv1" }], 11, 100, 10));

        var reviews = await ToListAsync(h.Client.Reviews.IterateAsync(new() { Offset = 10 }, Token));

        Assert.Single(reviews);
        Assert.Equal(["10"], h.Http.Last.Query["offset"]);
        Assert.Equal(["100"], h.Http.Last.Query["limit"]);
    }

    [Fact]
    public async Task IteratorIsLazy()
    {
        using var h = new Harness();
        var payments = h.Client.Payments.IterateAsync(cancellationToken: Token);
        Assert.Empty(h.Http.Requests);

        h.Http.Json(200, Harness.Page([], 10, 100, 0));
        Assert.Empty(await ToListAsync(payments));
        Assert.Single(h.Http.Requests);
    }

    [Fact]
    public async Task IteratorUsesTheLargestPageEachEndpointAllows()
    {
        using var h = new Harness();
        for (var i = 0; i < 4; i++)
        {
            h.Http.Json(200, Harness.Page([], 0));
        }

        await ToListAsync(h.Client.Orders.IterateBillsAsync(cancellationToken: Token));
        await ToListAsync(h.Client.Menu.IterateProductsAsync(new() { Expand = [ProductExpand.ModifierGroups] }, Token));
        await ToListAsync(h.Client.Stock.IterateMovesAsync(cancellationToken: Token));
        await ToListAsync(h.Client.Menu.IterateProductsAsync(cancellationToken: Token));

        Assert.Equal(["50", "50", "100", "100"], h.Http.Requests.Select(r => r.Query["limit"][0]));
    }

    [Fact]
    public async Task GetProductEncodesTheIdAndExpand()
    {
        using var h = new Harness();
        h.Http.Raw(200, Data(Product));

        var product = await h.Client.Menu.GetProductAsync("a/b c", [ProductExpand.Translations], Token);

        Assert.Equal("https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations", h.Http.Last.Url);
        Assert.Equal("Plov", product.Name);
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    public async Task EmptyIdIsRejected(string id)
    {
        using var h = new Harness();

        await Assert.ThrowsAnyAsync<ArgumentException>(() => h.Client.Orders.GetAsync(id, Token));
        await Assert.ThrowsAnyAsync<ArgumentException>(() => h.Client.Reservations.CancelAsync(id, Token));
        Assert.Empty(h.Http.Requests);
    }

    [Fact]
    public async Task CategoriesAndStopList()
    {
        using var h = new Harness();
        h.Http.Raw(200, """{"data": {"items": [{"name": "Salads", "position": 1, "products": 9, "available": 8}], "total": 1}}""");
        h.Http.Raw(200, """{"data": {"items": [{"id": "p9", "name": "Dolma", "category": "Main", "price": 9.5}], "total": 1}}""");

        Assert.Equal(8, (await h.Client.Menu.ListCategoriesAsync(Token))[0].Available);
        Assert.Equal("Dolma", (await h.Client.Menu.GetStopListAsync(Token))[0].Name);
        Assert.Equal(["/v1/menu/categories", "/v1/menu/stop-list"], h.Http.Requests.Select(r => r.Path));
    }

    [Fact]
    public async Task ReservationParsesNestedFieldsAndTimes()
    {
        using var h = new Harness();
        h.Http.Raw(200, Data(Reservation));

        var reservation = await h.Client.Reservations.GetAsync("res1", Token);

        Assert.Equal(new DateTimeOffset(2026, 11, 20, 15, 30, 0, TimeSpan.Zero), reservation.StartsAt);
        Assert.Equal(new DateTimeOffset(2026, 11, 20, 17, 30, 0, TimeSpan.Zero).AddTicks(1234567), reservation.EndsAt);
        Assert.Equal(TimeSpan.Zero, reservation.EndsAt!.Value.Offset);
        Assert.Equal(new DateTimeOffset(2026, 11, 11, 10, 0, 0, 500, TimeSpan.Zero), reservation.CreatedAt);
        Assert.Null(reservation.DecidedAt);
        Assert.Equal(ReservationStatus.Pending, reservation.Status);
        Assert.Equal(ReservationSource.OpenApi, reservation.Source);
        Assert.Equal("T5", reservation.Table!.Label);
        Assert.Equal("+994501234567", reservation.Guest!.Phone);
        Assert.Null(reservation.Guest.Email);
        Assert.Equal(2, reservation.PreOrder![0].Qty);
        Assert.Equal(14.5, reservation.PreOrder[0].Price);
        Assert.Equal(0.0, reservation.DepositPaid);
        Assert.True(reservation.ChildChair);
    }

    [Fact]
    public async Task Availability()
    {
        using var h = new Harness();
        h.Http.Raw(200, """
            {"data": {
              "startsAt": "2026-11-20T15:30:00Z",
              "endsAt": "2026-11-20T17:30:00Z",
              "durationMinutes": 120,
              "openTime": "10:00",
              "closeTime": "23:00",
              "tables": [{"id": "t5", "label": "T5", "hallId": "h1", "zone": "Terrace", "seats": 4, "free": true}]
            }}
            """);

        var result = await h.Client.Reservations.AvailabilityAsync(new DateOnly(2026, 11, 20), new TimeOnly(19, 30), 4, Token);

        Assert.Equal("/v1/reservations/availability", h.Http.Last.Path);
        var query = h.Http.Last.Query;
        Assert.Equal(["date", "time", "guests"], query.Keys);
        Assert.Equal(["2026-11-20"], query["date"]);
        Assert.Equal(["19:30"], query["time"]);
        Assert.Equal(["4"], query["guests"]);
        Assert.Equal(120, result.DurationMinutes);
        Assert.True(result.Tables![0].Free);

        h.Http.Raw(200, """{"data": {}}""");
        await h.Client.Reservations.AvailabilityAsync(new DateOnly(2026, 11, 20), new TimeOnly(9, 5), cancellationToken: Token);
        Assert.Equal(["date", "time"], h.Http.Last.Query.Keys);
        Assert.Equal(["09:05"], h.Http.Last.Query["time"]);
    }

    [Fact]
    public async Task CreateReservationPostsJsonAndReportsCreated()
    {
        using var h = new Harness();
        h.Http.Raw(201, Data(Reservation));

        var result = await h.Client.Reservations.CreateAsync(
            Booking with
            {
                ChildChair = true,
                PreOrder = [new PreOrderLine("p1", 2), new PreOrderLine { ItemId = "p2", Qty = 1, Note = "no onion" }],
                ExternalRef = "acme-991",
            },
            Token);

        var request = h.Http.Last;
        Assert.Equal(HttpMethod.Post, request.Method);
        Assert.Equal("https://open-api.noosh24.com/v1/reservations", request.Url);
        Assert.Equal("application/json", request.Headers["content-type"]);
        Assert.Equal(
            """{"date":"2026-11-20","time":"19:30","guests":4,"guestName":"Aysel Məmmədova","phone":"+994501234567","childChair":true,"preOrder":[{"itemId":"p1","qty":2},{"itemId":"p2","qty":1,"note":"no onion"}],"externalRef":"acme-991"}""",
            request.BodyText);
        Assert.True(request.Body!.AsSpan().IndexOf(Encoding.UTF8.GetBytes("Məmmədova")) >= 0);
        using (var body = JsonDocument.Parse(request.Body))
        {
            Assert.False(body.RootElement.TryGetProperty("email", out _));
            Assert.False(body.RootElement.TryGetProperty("tableId", out _));
        }

        Assert.True(result.Created);
        Assert.Equal("K7Q2", result.Reservation.Code);
    }

    [Fact]
    public async Task CreateWithKnownExternalRefReturnsTheExistingBooking()
    {
        using var h = new Harness();
        h.Http.Raw(200, Data(Reservation));

        var result = await h.Client.Reservations.CreateAsync(Booking with { ExternalRef = "acme-991" }, Token);

        Assert.False(result.Created);
        Assert.Equal("res1", result.Reservation.Id);
    }

    [Fact]
    public async Task CreateWithExternalRefIsRetried()
    {
        using var h = new Harness();
        h.Http.Json(503, new { error = "temporarily_unavailable" }, new Dictionary<string, string> { ["Retry-After"] = "0" });
        h.Http.Raw(201, Data(Reservation));

        var result = await h.Client.Reservations.CreateAsync(Booking with { ExternalRef = "acme-991" }, Token);

        Assert.True(result.Created);
        Assert.Equal(2, h.Http.Requests.Count);
        Assert.Equal(h.Http.Requests[0].Body, h.Http.Requests[1].Body);
        Assert.Equal([0.0], h.Sleeps);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("  ")]
    public async Task CreateWithoutExternalRefIsNeverRetried(string? externalRef)
    {
        using var h = new Harness();
        h.Http.Json(503, new { error = "temporarily_unavailable" }, new Dictionary<string, string> { ["Retry-After"] = "0" });

        await Assert.ThrowsAnyAsync<ServerException>(() => h.Client.Reservations.CreateAsync(Booking with { ExternalRef = externalRef }, Token));
        Assert.Single(h.Http.Requests);
    }

    [Fact]
    public async Task CreateWithoutExternalRefIsNotRetriedOnConnectionErrors()
    {
        using var h = new Harness();
        h.Http.Fail(new HttpRequestException("connection reset"));

        await Assert.ThrowsAsync<ApiConnectionException>(() => h.Client.Reservations.CreateAsync(Booking, Token));
        Assert.Single(h.Http.Requests);
    }

    [Fact]
    public async Task TableTaken()
    {
        using var h = new Harness();
        h.Http.Json(409, new { error = "table_taken", message = "Bu masa seçilən vaxt üçün artıq tutulub" });

        var error = await Assert.ThrowsAsync<TableTakenException>(() => h.Client.Reservations.CreateAsync(Booking with { TableId = "t5", ExternalRef = "x" }, Token));

        Assert.Contains("artıq tutulub", error.Message, StringComparison.Ordinal);
        Assert.IsAssignableFrom<ConflictException>(error);
        Assert.Single(h.Http.Requests);
    }

    [Fact]
    public async Task Cancel()
    {
        using var h = new Harness();
        h.Http.Raw(200, Cancelled());

        var reservation = await h.Client.Reservations.CancelAsync("res1", Token);

        Assert.Equal(HttpMethod.Post, h.Http.Last.Method);
        Assert.Equal("https://open-api.noosh24.com/v1/reservations/res1/cancel", h.Http.Last.Url);
        Assert.Null(h.Http.Last.Body);
        Assert.False(h.Http.Last.Headers.ContainsKey("content-type"));
        Assert.Equal(ReservationStatus.Cancelled, reservation.Status);
    }

    [Fact]
    public async Task OrdersBillsPaymentsAndZReport()
    {
        using var h = new Harness();
        h.Http.Raw(200, """
            {"data": {
              "id": "o1", "number": "A-12", "dailyNumber": 12, "kind": "delivery", "status": "ready", "subtotal": 30,
              "items": [{"id": "i1", "productId": "p1", "name": "Plov", "qty": 2, "price": 15, "comp": false}],
              "delivery": {"status": "accepted", "platform": {"id": "wolt", "name": "Wolt", "ref": "W-1"}, "fee": 2, "acceptedAt": "2026-11-11T09:00:00Z"}
            }}
            """);
        h.Http.Raw(200, """{"data": {"id": "b1", "status": "paid", "orderIds": ["o1", "o2"], "total": 45.5, "closedAt": null}}""");
        h.Http.Raw(200, """
            {"data": {"id": "pay1", "method": "card", "amount": 20,
              "card": {"maskedPan": "4169********1234", "scheme": "visa", "bank": "Kapital"}, "platform": null}}
            """);
        h.Http.Raw(200, """{"data": {"date": "2026-11-10", "cash": 120.5}}""");

        var order = await h.Client.Orders.GetAsync("o1", Token);
        var bill = await h.Client.Orders.GetBillAsync("b1", Token);
        var payment = await h.Client.Payments.GetAsync("pay1", Token);
        var z = await h.Client.Payments.ZReportAsync(new DateOnly(2026, 11, 10), Token);

        Assert.Equal(OrderKind.Delivery, order.Kind);
        Assert.Equal(12, order.DailyNumber);
        Assert.Equal("Wolt", order.Delivery!.Platform!.Name);
        Assert.Equal(2.0, order.Delivery.Fee);
        Assert.Equal(new DateTimeOffset(2026, 11, 11, 9, 0, 0, TimeSpan.Zero), order.Delivery.AcceptedAt);
        Assert.Equal(15.0, order.Items![0].Price);
        Assert.Equal(["o1", "o2"], bill.OrderIds!);
        Assert.Equal(BillStatus.Paid, bill.Status);
        Assert.Null(bill.ClosedAt);
        Assert.Equal("4169********1234", payment.Card!.MaskedPan);
        Assert.Equal(PaymentMethod.Card, payment.Method);
        Assert.Null(payment.Platform);
        Assert.Equal(120.5, z["cash"].GetDouble());
        Assert.Equal("2026-11-10", z["date"].GetString());
        Assert.Equal(["2026-11-10"], h.Http.Last.Query["date"]);
        Assert.Equal(["/v1/orders/o1", "/v1/bills/b1", "/v1/payments/pay1", "/v1/reports/z"], h.Http.Requests.Select(r => r.Path));

        h.Http.Raw(200, """{"data": {}}""");
        Assert.Empty(await h.Client.Payments.ZReportAsync(cancellationToken: Token));
        Assert.Equal("https://open-api.noosh24.com/v1/reports/z", h.Http.Last.Url);
    }

    [Fact]
    public async Task OrderAndPaymentListsUseTheirPaths()
    {
        using var h = new Harness();
        for (var i = 0; i < 4; i++)
        {
            h.Http.Json(200, Harness.Page([], 0));
        }

        await h.Client.Reservations.ListAsync(cancellationToken: Token);
        await h.Client.Orders.ListBillsAsync(cancellationToken: Token);
        await h.Client.Payments.ListAsync(cancellationToken: Token);
        await h.Client.Stock.ListMovesAsync(cancellationToken: Token);

        Assert.Equal(["/v1/reservations", "/v1/bills", "/v1/payments", "/v1/stock/moves"], h.Http.Requests.Select(r => r.Path));
    }

    [Fact]
    public async Task TablesLoyaltyStockAndReviews()
    {
        using var h = new Harness();
        h.Http.Raw(200, """{"data": {"items": [{"id": "t1", "label": "T1", "status": "occupied", "billTotal": 42.1}], "total": 1}}""");
        h.Http.Raw(200, """{"data": {"items": [{"id": "h1", "name": "Main", "position": 0}], "total": 1}}""");
        h.Http.Raw(200, """{"data": {"stampsNeeded": 8, "earnBy": "visit", "rewardProductIds": ["p1"]}}""");
        h.Http.Json(200, Harness.Page([new { id = "card1", stamps = 5, lastVisitAt = (string?)null }], 1, 100));
        h.Http.Json(200, Harness.Page([new { id = "ing1", name = "Rice", stock = 12, byStore = new Dictionary<string, double> { ["s1"] = 10, ["s2"] = 2.5 } }], 1));
        h.Http.Raw(200, """{"data": {"items": [{"id": "s1", "name": "Main", "isDefault": true, "stations": ["hot"]}], "total": 1}}""");
        h.Http.Json(200, Harness.Page([new { id = "rv1", overall = 4.5, ratings = new { food = 5, service = 4 }, reply = (string?)null }], 1));

        var table = (await h.Client.Tables.ListAsync(Token))[0];
        Assert.Equal(42.1, table.BillTotal);
        Assert.Equal(TableStatus.Occupied, table.Status);
        Assert.Equal("Main", (await h.Client.Tables.ListHallsAsync(Token))[0].Name);
        var program = await h.Client.Loyalty.GetProgramAsync(Token);
        Assert.Equal(8, program.StampsNeeded);
        Assert.Equal(LoyaltyProgramEarnBy.Visit, program.EarnBy);
        var cards = await h.Client.Loyalty.ListCardsAsync(cancellationToken: Token);
        Assert.False(cards.HasMore);
        Assert.Null(cards[0].LastVisitAt);
        var ingredient = (await h.Client.Stock.ListIngredientsAsync(cancellationToken: Token)).Items[0];
        Assert.Equal(12.0, ingredient.Stock);
        Assert.Equal(new Dictionary<string, double> { ["s1"] = 10.0, ["s2"] = 2.5 }, ingredient.ByStore!);
        var store = (await h.Client.Stock.ListStoresAsync(Token))[0];
        Assert.True(store.IsDefault);
        Assert.Equal(["hot"], store.Stations!);
        var review = (await h.Client.Reviews.ListAsync(cancellationToken: Token)).Items[0];
        Assert.Equal(5.0, review.Ratings!.Food);
        Assert.Null(review.Ratings.Price);
        Assert.Null(review.Reply);
        Assert.Equal(
            ["/v1/tables", "/v1/halls", "/v1/loyalty/program", "/v1/loyalty/cards", "/v1/stock/ingredients", "/v1/stock/stores", "/v1/reviews"],
            h.Http.Requests.Select(r => r.Path));
    }

    [Fact]
    public async Task IteratorsOfEveryGroupUseTheirPaths()
    {
        using var h = new Harness();
        for (var i = 0; i < 6; i++)
        {
            h.Http.Json(200, Harness.Page([], 0));
        }

        await ToListAsync(h.Client.Reservations.IterateAsync(cancellationToken: Token));
        await ToListAsync(h.Client.Orders.IterateAsync(cancellationToken: Token));
        await ToListAsync(h.Client.Loyalty.IterateCardsAsync(cancellationToken: Token));
        await ToListAsync(h.Client.Stock.IterateIngredientsAsync(cancellationToken: Token));
        await ToListAsync(h.Client.Reviews.IterateAsync(cancellationToken: Token));
        await ToListAsync(h.Client.Customers.IterateAsync(cancellationToken: Token));

        Assert.Equal(
            ["/v1/reservations", "/v1/orders", "/v1/loyalty/cards", "/v1/stock/ingredients", "/v1/reviews", "/v1/customers"],
            h.Http.Requests.Select(r => r.Path));
        Assert.All(h.Http.Requests, r => Assert.Equal(["100"], r.Query["limit"]));
    }

    [Fact]
    public async Task ModelsTolerateMissingAndUnknownFields()
    {
        using var h = new Harness();
        h.Http.Raw(201, """{"data": {"id": "res9", "code": "ZZ11", "status": "pending", "brandNew": 1}}""");

        var result = await h.Client.Reservations.CreateAsync(Booking, Token);

        Assert.True(result.Created);
        Assert.Equal("ZZ11", result.Reservation.Code);
        Assert.Null(result.Reservation.Guest);
        Assert.Null(result.Reservation.PreOrder);
        Assert.Null(result.Reservation.StartsAt);
        Assert.Equal(1, result.Reservation.ExtensionData!["brandNew"].GetInt32());
    }

    [Fact]
    public async Task BadTimestampsBecomeNull()
    {
        using var h = new Harness();
        h.Http.Raw(200, """{"data": {"id": "c1", "createdAt": "", "updatedAt": "not a time"}}""");

        var customer = await h.Client.Customers.GetAsync("c1", Token);

        Assert.Null(customer.CreatedAt);
        Assert.Null(customer.UpdatedAt);
    }
}
