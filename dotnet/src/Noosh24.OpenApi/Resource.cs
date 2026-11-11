using System.Globalization;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Text.Json.Serialization.Metadata;

namespace Noosh24.OpenApi;

public abstract class Resource
{
    private protected Resource(Noosh24Client client)
    {
        Client = client;
    }

    private protected Noosh24Client Client { get; }

    private protected async Task<Page<T>> PageAsync<T>(string path, JsonTypeInfo<T> info, ListOptions? options, CancellationToken cancellationToken)
    {
        var response = await Client.SendAsync(HttpMethod.Get, path, ListQuery(options), null, true, cancellationToken).ConfigureAwait(false);
        var items = Json.Items(response.Status, response.Data, info);
        return new Page<T>(
            items,
            Json.Int(response.Data, "total") ?? items.Count,
            Json.Int(response.Data, "limit") ?? options?.Limit ?? items.Count,
            Json.Int(response.Data, "offset") ?? options?.Offset ?? 0);
    }

    private protected async IAsyncEnumerable<T> PaginateAsync<T>(string path, JsonTypeInfo<T> info, ListOptions options, int pageSize, [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        var current = options with { Limit = options.Limit ?? pageSize, Offset = options.Offset ?? 0 };
        while (true)
        {
            var page = await PageAsync(path, info, current, cancellationToken).ConfigureAwait(false);
            foreach (var item in page.Items)
            {
                yield return item;
            }

            if (!page.HasMore)
            {
                yield break;
            }

            current = current with { Offset = page.NextOffset };
        }
    }

    private protected async Task<IReadOnlyList<T>> AllAsync<T>(string path, JsonTypeInfo<T> info, CancellationToken cancellationToken)
    {
        var response = await Client.SendAsync(HttpMethod.Get, path, null, null, true, cancellationToken).ConfigureAwait(false);
        return Json.Items(response.Status, response.Data, info);
    }

    private protected async Task<T> OneAsync<T>(string path, JsonTypeInfo<T> info, IReadOnlyList<KeyValuePair<string, string>>? query, CancellationToken cancellationToken)
    {
        var response = await Client.SendAsync(HttpMethod.Get, path, query, null, true, cancellationToken).ConfigureAwait(false);
        return Json.Model(response.Status, response.Data, info);
    }

    private protected async Task<T> PostAsync<T>(string path, JsonTypeInfo<T> info, CancellationToken cancellationToken)
    {
        var response = await Client.SendAsync(HttpMethod.Post, path, null, null, true, cancellationToken).ConfigureAwait(false);
        return Json.Model(response.Status, response.Data, info);
    }

    internal static string PathId(string id, [CallerArgumentExpression(nameof(id))] string? name = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(id, name);
        return Uri.EscapeDataString(id);
    }

    internal static string Date(DateOnly date) => date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);

    internal static List<KeyValuePair<string, string>> ListQuery(ListOptions? options)
    {
        var query = new List<KeyValuePair<string, string>>();
        if (options is null)
        {
            return query;
        }

        if (options.Limit is { } limit)
        {
            query.Add(new("limit", limit.ToString(CultureInfo.InvariantCulture)));
        }

        if (options.Offset is { } offset)
        {
            query.Add(new("offset", offset.ToString(CultureInfo.InvariantCulture)));
        }

        foreach (var sort in options.Sort ?? [])
        {
            if (!string.IsNullOrEmpty(sort))
            {
                query.Add(new("sort", sort));
            }
        }

        var where = options.Where?.ToString();
        if (!string.IsNullOrEmpty(where))
        {
            query.Add(new("where", where));
        }

        if (options is ProductListOptions products)
        {
            AddExpand(query, products.Expand);
        }

        return query;
    }

    internal static void AddExpand(List<KeyValuePair<string, string>> query, IEnumerable<string>? expand)
    {
        foreach (var value in expand ?? [])
        {
            if (!string.IsNullOrEmpty(value))
            {
                query.Add(new("expand", value));
            }
        }
    }
}

public sealed class Menu : Resource
{
    internal Menu(Noosh24Client client)
        : base(client)
    {
    }

    public Task<IReadOnlyList<Category>> ListCategoriesAsync(CancellationToken cancellationToken = default) =>
        AllAsync("/menu/categories", Json.Context.Category, cancellationToken);

    public Task<Page<Product>> ListProductsAsync(ProductListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/menu/products", Json.Context.Product, options, cancellationToken);

    public IAsyncEnumerable<Product> IterateProductsAsync(ProductListOptions? options = null, CancellationToken cancellationToken = default)
    {
        options ??= new ProductListOptions();
        var pageSize = options.Expand?.Any(value => !string.IsNullOrEmpty(value)) == true ? 50 : 100;
        return PaginateAsync("/menu/products", Json.Context.Product, options, pageSize, cancellationToken);
    }

    public Task<Product> GetProductAsync(string productId, IEnumerable<string>? expand = null, CancellationToken cancellationToken = default)
    {
        var path = "/menu/products/" + PathId(productId);
        var query = new List<KeyValuePair<string, string>>();
        AddExpand(query, expand);
        return OneAsync(path, Json.Context.Product, query, cancellationToken);
    }

    public Task<IReadOnlyList<StopListItem>> GetStopListAsync(CancellationToken cancellationToken = default) =>
        AllAsync("/menu/stop-list", Json.Context.StopListItem, cancellationToken);
}

public sealed class Reservations : Resource
{
    internal Reservations(Noosh24Client client)
        : base(client)
    {
    }

    public Task<Page<Reservation>> ListAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/reservations", Json.Context.Reservation, options, cancellationToken);

    public IAsyncEnumerable<Reservation> IterateAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PaginateAsync("/reservations", Json.Context.Reservation, options ?? new ListOptions(), 100, cancellationToken);

    public Task<Reservation> GetAsync(string reservationId, CancellationToken cancellationToken = default) =>
        OneAsync("/reservations/" + PathId(reservationId), Json.Context.Reservation, null, cancellationToken);

    public Task<TableAvailability> AvailabilityAsync(DateOnly date, TimeOnly time, int? guests = null, CancellationToken cancellationToken = default)
    {
        var query = new List<KeyValuePair<string, string>>
        {
            new("date", Date(date)),
            new("time", time.ToString("HH:mm", CultureInfo.InvariantCulture)),
        };
        if (guests is { } count)
        {
            query.Add(new("guests", count.ToString(CultureInfo.InvariantCulture)));
        }

        return OneAsync("/reservations/availability", Json.Context.TableAvailability, query, cancellationToken);
    }

    public async Task<CreateReservationResult> CreateAsync(NewReservation reservation, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(reservation);
        var body = JsonSerializer.SerializeToUtf8Bytes(reservation, Json.Context.NewReservation);
        var idempotent = !string.IsNullOrWhiteSpace(reservation.ExternalRef);
        var response = await Client.SendAsync(HttpMethod.Post, "/reservations", null, body, idempotent, cancellationToken).ConfigureAwait(false);
        return new CreateReservationResult(Json.Model(response.Status, response.Data, Json.Context.Reservation), response.Status == 201);
    }

    public Task<Reservation> CancelAsync(string reservationId, CancellationToken cancellationToken = default) =>
        PostAsync("/reservations/" + PathId(reservationId) + "/cancel", Json.Context.Reservation, cancellationToken);
}

public sealed class Orders : Resource
{
    internal Orders(Noosh24Client client)
        : base(client)
    {
    }

    public Task<Page<Order>> ListAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/orders", Json.Context.Order, options, cancellationToken);

    public IAsyncEnumerable<Order> IterateAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PaginateAsync("/orders", Json.Context.Order, options ?? new ListOptions(), 100, cancellationToken);

    public Task<Order> GetAsync(string orderId, CancellationToken cancellationToken = default) =>
        OneAsync("/orders/" + PathId(orderId), Json.Context.Order, null, cancellationToken);

    public Task<Page<Bill>> ListBillsAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/bills", Json.Context.Bill, options, cancellationToken);

    public IAsyncEnumerable<Bill> IterateBillsAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PaginateAsync("/bills", Json.Context.Bill, options ?? new ListOptions(), 50, cancellationToken);

    public Task<Bill> GetBillAsync(string billId, CancellationToken cancellationToken = default) =>
        OneAsync("/bills/" + PathId(billId), Json.Context.Bill, null, cancellationToken);
}

public sealed class Payments : Resource
{
    internal Payments(Noosh24Client client)
        : base(client)
    {
    }

    public Task<Page<Payment>> ListAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/payments", Json.Context.Payment, options, cancellationToken);

    public IAsyncEnumerable<Payment> IterateAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PaginateAsync("/payments", Json.Context.Payment, options ?? new ListOptions(), 100, cancellationToken);

    public Task<Payment> GetAsync(string paymentId, CancellationToken cancellationToken = default) =>
        OneAsync("/payments/" + PathId(paymentId), Json.Context.Payment, null, cancellationToken);

    public async Task<IReadOnlyDictionary<string, JsonElement>> ZReportAsync(DateOnly? date = null, CancellationToken cancellationToken = default)
    {
        List<KeyValuePair<string, string>>? query = date is { } day ? [new("date", Date(day))] : null;
        var response = await Client.SendAsync(HttpMethod.Get, "/reports/z", query, null, true, cancellationToken).ConfigureAwait(false);
        return response.Data.ValueKind == JsonValueKind.Object
            ? Json.Model(response.Status, response.Data, Json.Context.DictionaryStringJsonElement)
            : new Dictionary<string, JsonElement>();
    }
}

public sealed class Tables : Resource
{
    internal Tables(Noosh24Client client)
        : base(client)
    {
    }

    public Task<IReadOnlyList<Table>> ListAsync(CancellationToken cancellationToken = default) =>
        AllAsync("/tables", Json.Context.Table, cancellationToken);

    public Task<IReadOnlyList<Hall>> ListHallsAsync(CancellationToken cancellationToken = default) =>
        AllAsync("/halls", Json.Context.Hall, cancellationToken);
}

public sealed class Customers : Resource
{
    internal Customers(Noosh24Client client)
        : base(client)
    {
    }

    public Task<Page<Customer>> ListAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/customers", Json.Context.Customer, options, cancellationToken);

    public IAsyncEnumerable<Customer> IterateAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PaginateAsync("/customers", Json.Context.Customer, options ?? new ListOptions(), 100, cancellationToken);

    public Task<Customer> GetAsync(string customerId, CancellationToken cancellationToken = default) =>
        OneAsync("/customers/" + PathId(customerId), Json.Context.Customer, null, cancellationToken);
}

public sealed class Loyalty : Resource
{
    internal Loyalty(Noosh24Client client)
        : base(client)
    {
    }

    public Task<LoyaltyProgram> GetProgramAsync(CancellationToken cancellationToken = default) =>
        OneAsync("/loyalty/program", Json.Context.LoyaltyProgram, null, cancellationToken);

    public Task<Page<LoyaltyCard>> ListCardsAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/loyalty/cards", Json.Context.LoyaltyCard, options, cancellationToken);

    public IAsyncEnumerable<LoyaltyCard> IterateCardsAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PaginateAsync("/loyalty/cards", Json.Context.LoyaltyCard, options ?? new ListOptions(), 100, cancellationToken);
}

public sealed class Stock : Resource
{
    internal Stock(Noosh24Client client)
        : base(client)
    {
    }

    public Task<Page<Ingredient>> ListIngredientsAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/stock/ingredients", Json.Context.Ingredient, options, cancellationToken);

    public IAsyncEnumerable<Ingredient> IterateIngredientsAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PaginateAsync("/stock/ingredients", Json.Context.Ingredient, options ?? new ListOptions(), 100, cancellationToken);

    public Task<Page<StockMove>> ListMovesAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/stock/moves", Json.Context.StockMove, options, cancellationToken);

    public IAsyncEnumerable<StockMove> IterateMovesAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PaginateAsync("/stock/moves", Json.Context.StockMove, options ?? new ListOptions(), 100, cancellationToken);

    public Task<IReadOnlyList<StockStore>> ListStoresAsync(CancellationToken cancellationToken = default) =>
        AllAsync("/stock/stores", Json.Context.StockStore, cancellationToken);
}

public sealed class Reviews : Resource
{
    internal Reviews(Noosh24Client client)
        : base(client)
    {
    }

    public Task<Page<Review>> ListAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PageAsync("/reviews", Json.Context.Review, options, cancellationToken);

    public IAsyncEnumerable<Review> IterateAsync(ListOptions? options = null, CancellationToken cancellationToken = default) =>
        PaginateAsync("/reviews", Json.Context.Review, options ?? new ListOptions(), 100, cancellationToken);
}
