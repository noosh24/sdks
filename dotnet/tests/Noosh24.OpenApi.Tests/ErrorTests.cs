using Noosh24.OpenApi;

namespace Noosh24.OpenApi.Tests;

public sealed class ErrorTests
{
    private static CancellationToken Token => TestContext.Current.CancellationToken;

    public static TheoryData<int, string?, Type, Type> Cases => new()
    {
        { 400, "validation_error", typeof(ValidationException), typeof(ApiException) },
        { 401, "no_api_key", typeof(NoApiKeyException), typeof(AuthenticationException) },
        { 401, "invalid_api_key", typeof(InvalidApiKeyException), typeof(AuthenticationException) },
        { 403, "insufficient_scope", typeof(InsufficientScopeException), typeof(PermissionDeniedException) },
        { 403, "module_not_enabled", typeof(ModuleNotEnabledException), typeof(PermissionDeniedException) },
        { 403, "venue_suspended", typeof(VenueSuspendedException), typeof(PermissionDeniedException) },
        { 403, "not_your_reservation", typeof(NotYourReservationException), typeof(PermissionDeniedException) },
        { 404, "not_found", typeof(NotFoundException), typeof(ApiException) },
        { 404, "table_not_found", typeof(TableNotFoundException), typeof(NotFoundException) },
        { 409, "table_taken", typeof(TableTakenException), typeof(ConflictException) },
        { 409, "cannot_cancel", typeof(CannotCancelException), typeof(ConflictException) },
        { 422, "outside_hours", typeof(OutsideHoursException), typeof(UnprocessableException) },
        { 422, "in_the_past", typeof(InThePastException), typeof(UnprocessableException) },
        { 422, "table_too_small", typeof(TableTooSmallException), typeof(UnprocessableException) },
        { 429, "rate_limit_exceeded", typeof(RateLimitException), typeof(ApiException) },
        { 503, "temporarily_unavailable", typeof(TemporarilyUnavailableException), typeof(ServerException) },
        { 403, "something_new", typeof(PermissionDeniedException), typeof(ApiException) },
        { 409, "something_new", typeof(ConflictException), typeof(ApiException) },
        { 500, "query_failed", typeof(ServerException), typeof(ApiException) },
        { 418, null, typeof(ApiException), typeof(Noosh24Exception) },
    };

    [Theory]
    [MemberData(nameof(Cases))]
    public async Task MapsErrorCodes(int status, string? code, Type type, Type parent)
    {
        using var h = new Harness(new Noosh24ClientOptions { MaxRetries = 0 });
        if (code is null)
        {
            h.Http.Json(status, new { nope = true });
        }
        else
        {
            h.Http.Json(status, new { error = code, message = "Mesaj" });
        }

        var error = await Assert.ThrowsAnyAsync<ApiException>(() => h.Client.Customers.GetAsync("c1", Token));

        Assert.Equal(type, error.GetType());
        Assert.IsAssignableFrom(parent, error);
        Assert.IsAssignableFrom<Noosh24Exception>(error);
        Assert.Equal(status, error.Status);
        Assert.Equal(code, error.Code);
        Assert.Equal(code is null ? $"HTTP {status}" : "Mesaj", error.Message);
    }

    [Fact]
    public async Task MissingMessageFallsBackToTheCode()
    {
        using var h = new Harness(new Noosh24ClientOptions { MaxRetries = 0 });
        h.Http.Json(404, new { error = "not_found" });

        var error = await Assert.ThrowsAsync<NotFoundException>(() => h.Client.Customers.GetAsync("c1", Token));

        Assert.Equal("not_found", error.Message);
    }

    [Fact]
    public async Task ValidationErrorIsNotRetried()
    {
        using var h = new Harness();
        h.Http.Json(400, new { error = "validation_error", message = "\"nope\" is not a filterable field on this resource" });

        var error = await Assert.ThrowsAsync<ValidationException>(() => h.Client.Menu.ListProductsAsync(new() { Where = "nope = 1" }, Token));

        Assert.Contains("not a filterable field", error.Message, StringComparison.Ordinal);
        Assert.Single(h.Http.Requests);
        Assert.Empty(h.Sleeps);
    }
}
