namespace Noosh24.OpenApi;

public sealed record Noosh24ClientOptions
{
    public string BaseUrl { get; init; } = Noosh24Client.DefaultBaseUrl;

    public TimeSpan Timeout { get; init; } = TimeSpan.FromSeconds(30);

    public int MaxRetries { get; init; } = 2;

    public string? UserAgent { get; init; }

    public Func<TimeSpan, CancellationToken, Task>? Delay { get; init; }
}
