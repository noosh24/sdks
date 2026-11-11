using System.Net.Http;
using Noosh24.OpenApi;

namespace Noosh24.OpenApi.Tests;

public sealed class ClientTests
{
    private static CancellationToken Token => TestContext.Current.CancellationToken;

    [Fact]
    public async Task SendsKeyAndHeadersToDefaultBaseUrl()
    {
        using var h = new Harness();
        h.Http.Raw(200, """
            {"data": {
              "restaurant": {"id": "r1", "name": "Masago", "slug": "masago"},
              "key": {"id": "k1", "name": "Wolt", "prefix": "nsk_Ab3dE9xQ", "scopes": ["menu:read", "orders:read"]},
              "subscription": {"status": "active", "modules": ["loyalty"]},
              "features": {"loyalty": true, "inventory": false}
            }}
            """);

        var me = await h.Client.WhoamiAsync(Token);

        var request = h.Http.Last;
        Assert.Equal(HttpMethod.Get, request.Method);
        Assert.Equal("https://open-api.noosh24.com/v1/whoami", request.Url);
        Assert.Equal("Bearer nsk_test_123", request.Headers["authorization"]);
        Assert.Equal("application/json", request.Headers["accept"]);
        Assert.Equal("noosh24-dotnet/" + Noosh24Client.Version, request.Headers["user-agent"]);
        Assert.Null(request.Body);
        Assert.Equal("Masago", me.Restaurant!.Name);
        Assert.Equal(["menu:read", "orders:read"], me.Key!.Scopes!);
        Assert.Equal(SubscriptionStatus.Active, me.Subscription!.Status);
        Assert.True(me.Features!.Loyalty);
        Assert.False(me.Features.Inventory);
    }

    [Fact]
    public async Task CustomBaseUrlAndUserAgent()
    {
        using var h = new Harness(new Noosh24ClientOptions { BaseUrl = "http://localhost:8080/v1/", UserAgent = "acme-pos/2.1" });
        h.Http.Raw(200, """{"data": {}}""");

        await h.Client.WhoamiAsync(Token);

        Assert.Equal("http://localhost:8080/v1/whoami", h.Http.Last.Url);
        Assert.Equal("acme-pos/2.1 noosh24-dotnet/" + Noosh24Client.Version, h.Http.Last.Headers["user-agent"]);
    }

    [Theory]
    [InlineData("")]
    [InlineData("  ")]
    public void RejectsEmptyKey(string key)
    {
        Assert.ThrowsAny<ArgumentException>(() => new Noosh24Client(key));
    }

    [Fact]
    public void RejectsNullKey()
    {
        Assert.Throws<ArgumentNullException>(() => new Noosh24Client(null!));
    }

    [Fact]
    public async Task DisposeReleasesOwnHttpClient()
    {
        var client = new Noosh24Client("nsk_x");
        Assert.NotNull(client.Menu);
        client.Dispose();
        client.Dispose();

        await Assert.ThrowsAsync<ObjectDisposedException>(() => client.WhoamiAsync(Token));
    }

    [Fact]
    public async Task DoesNotDisposeInjectedHttpClient()
    {
        var http = new MockHttp().Raw(200, """{"data": {}}""");
        using var httpClient = new HttpClient(http);
        new Noosh24Client("nsk_x", httpClient).Dispose();

        using var again = new Noosh24Client("nsk_x", httpClient);
        await again.WhoamiAsync(Token);
        Assert.Single(http.Requests);
    }

    [Fact]
    public async Task RetriesRateLimitAfterRetryAfter()
    {
        using var h = new Harness();
        h.Http.Json(429, new { error = "rate_limit_exceeded", message = "slow down" }, new Dictionary<string, string> { ["Retry-After"] = "3" });
        h.Http.Raw(200, """{"data": {"items": [], "total": 0}}""");

        Assert.Empty(await h.Client.Tables.ListAsync(Token));
        Assert.Equal(2, h.Http.Requests.Count);
        Assert.Equal([3.0], h.Sleeps);
    }

    [Fact]
    public async Task GivesUpAfterMaxRetries()
    {
        using var h = new Harness(new Noosh24ClientOptions { MaxRetries = 1 });
        h.Http.Json(429, new { error = "rate_limit_exceeded", message = "slow down" }, new Dictionary<string, string> { ["Retry-After"] = "1" });
        h.Http.Json(429, new { error = "rate_limit_exceeded", message = "slow down" }, new Dictionary<string, string> { ["Retry-After"] = "7" });

        var error = await Assert.ThrowsAsync<RateLimitException>(() => h.Client.Tables.ListAsync(Token));

        Assert.Equal(429, error.Status);
        Assert.Equal("rate_limit_exceeded", error.Code);
        Assert.Equal(7, error.RetryAfter);
        Assert.Equal("7", error.Headers["retry-after"]);
        Assert.Equal("slow down", error.Message);
        Assert.Equal(2, h.Http.Requests.Count);
        Assert.Equal([1.0], h.Sleeps);
    }

    [Fact]
    public async Task RetryAfterIsNullWithoutTheHeader()
    {
        using var h = new Harness(new Noosh24ClientOptions { MaxRetries = 0 });
        h.Http.Json(429, new { error = "rate_limit_exceeded" });

        var error = await Assert.ThrowsAsync<RateLimitException>(() => h.Client.Tables.ListAsync(Token));

        Assert.Null(error.RetryAfter);
        Assert.Equal("rate_limit_exceeded", error.Message);
    }

    [Fact]
    public async Task DoesNotWaitLongerThanAMinute()
    {
        using var h = new Harness();
        h.Http.Json(429, new { error = "rate_limit_exceeded" }, new Dictionary<string, string> { ["Retry-After"] = "120" });

        var error = await Assert.ThrowsAsync<RateLimitException>(() => h.Client.Tables.ListAsync(Token));

        Assert.Equal(120, error.RetryAfter);
        Assert.Single(h.Http.Requests);
        Assert.Empty(h.Sleeps);
    }

    [Fact]
    public async Task BacksOffOnTemporarilyUnavailable()
    {
        using var h = new Harness();
        for (var i = 0; i < 3; i++)
        {
            h.Http.Json(503, new { error = "temporarily_unavailable", message = "try again" });
        }

        await Assert.ThrowsAsync<TemporarilyUnavailableException>(() => h.Client.Tables.ListHallsAsync(Token));
        Assert.Equal(3, h.Http.Requests.Count);
        Assert.Equal([0.5, 1.0], h.Sleeps);
    }

    [Fact]
    public async Task RetriesConnectionErrorsOnReads()
    {
        using var h = new Harness(new Noosh24ClientOptions { MaxRetries = 1 });
        h.Http.Fail(new HttpRequestException("connection reset"));
        h.Http.Raw(200, """{"data": {"items": [{"id": "h1", "name": "Main", "position": 1}], "total": 1}}""");

        Assert.Equal("Main", (await h.Client.Tables.ListHallsAsync(Token))[0].Name);
        Assert.Equal([0.5], h.Sleeps);

        h.Http.Fail(new HttpRequestException("connection reset")).Fail(new HttpRequestException("connection reset"));
        var error = await Assert.ThrowsAsync<ApiConnectionException>(() => h.Client.Tables.ListHallsAsync(Token));
        Assert.Contains("connection reset", error.Message, StringComparison.Ordinal);
        Assert.IsType<HttpRequestException>(error.InnerException);
    }

    [Fact]
    public async Task Timeout()
    {
        using var h = new Harness(new Noosh24ClientOptions { MaxRetries = 0, Timeout = TimeSpan.FromMilliseconds(50) });
        h.Http.Hang();

        var error = await Assert.ThrowsAsync<ApiTimeoutException>(() => h.Client.WhoamiAsync(Token));

        Assert.IsAssignableFrom<ApiConnectionException>(error);
    }

    [Fact]
    public async Task HttpClientTimeoutIsATimeoutAndIsRetried()
    {
        using var h = new Harness(new Noosh24ClientOptions { MaxRetries = 1 });
        h.Http.Fail(new TaskCanceledException("The request was canceled due to the configured HttpClient.Timeout", new TimeoutException()));
        h.Http.Fail(new TaskCanceledException("The request was canceled due to the configured HttpClient.Timeout", new TimeoutException()));

        await Assert.ThrowsAsync<ApiTimeoutException>(() => h.Client.WhoamiAsync(Token));
        Assert.Equal(2, h.Http.Requests.Count);
        Assert.Equal([0.5], h.Sleeps);
    }

    [Fact]
    public async Task CallerCancellationIsNotATimeout()
    {
        using var h = new Harness();
        h.Http.Hang();
        using var cancel = new CancellationTokenSource(TimeSpan.FromMilliseconds(50));

        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => h.Client.WhoamiAsync(cancel.Token));
        Assert.Single(h.Http.Requests);
    }

    [Fact]
    public async Task BodyThatIsNotJsonIsAnApiError()
    {
        using var h = new Harness();
        h.Http.Raw(200, "<html>gateway</html>");

        var error = await Assert.ThrowsAsync<ApiException>(() => h.Client.WhoamiAsync(Token));

        Assert.Equal(200, error.Status);
        Assert.Null(error.Code);
        Assert.Equal("<html>gateway</html>", error.Body);
    }

    [Fact]
    public async Task BodyWithoutDataIsAnApiError()
    {
        using var h = new Harness();
        h.Http.Raw(200, """{"items": []}""");

        await Assert.ThrowsAsync<ApiException>(() => h.Client.WhoamiAsync(Token));
    }

    [Fact]
    public void BuildsRepeatedQueryParameters()
    {
        var query = Noosh24Client.QueryString(
        [
            new("sort", "price desc"),
            new("sort", "name asc"),
            new("where", "a = 1"),
            new("available", "true"),
        ]);

        Assert.Equal("?sort=price%20desc&sort=name%20asc&where=a%20%3D%201&available=true", query);
        Assert.Equal(string.Empty, Noosh24Client.QueryString([]));
    }
}
