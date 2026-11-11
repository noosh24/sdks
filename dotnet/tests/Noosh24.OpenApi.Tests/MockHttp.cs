using System.Net;
using System.Text;
using System.Text.Json;
using Noosh24.OpenApi;

namespace Noosh24.OpenApi.Tests;

public sealed record RecordedRequest(HttpMethod Method, Uri Uri, IReadOnlyDictionary<string, string> Headers, byte[]? Body)
{
    public string Url => Uri.AbsoluteUri;

    public string Path => Uri.AbsolutePath;

    public string? BodyText => Body is null ? null : Encoding.UTF8.GetString(Body);

    public Dictionary<string, List<string>> Query
    {
        get
        {
            var query = new Dictionary<string, List<string>>(StringComparer.Ordinal);
            var text = Uri.Query.TrimStart('?');
            if (text.Length == 0)
            {
                return query;
            }

            foreach (var pair in text.Split('&'))
            {
                var parts = pair.Split('=', 2);
                var name = Uri.UnescapeDataString(parts[0]);
                var value = parts.Length > 1 ? Uri.UnescapeDataString(parts[1]) : string.Empty;
                if (!query.TryGetValue(name, out var values))
                {
                    query[name] = values = [];
                }

                values.Add(value);
            }

            return query;
        }
    }
}

public sealed class MockHttp : HttpMessageHandler
{
    private readonly Queue<Func<CancellationToken, Task<HttpResponseMessage>>> _queue = new();

    public List<RecordedRequest> Requests { get; } = [];

    public RecordedRequest Last => Requests[^1];

    public MockHttp Json(int status, object body, IDictionary<string, string>? headers = null) =>
        Raw(status, JsonSerializer.Serialize(body), headers);

    public MockHttp Raw(int status, string text, IDictionary<string, string>? headers = null)
    {
        _queue.Enqueue(_ =>
        {
            var response = new HttpResponseMessage((HttpStatusCode)status)
            {
                Content = new StringContent(text, Encoding.UTF8, "application/json"),
            };
            foreach (var (name, value) in headers ?? new Dictionary<string, string>())
            {
                response.Headers.TryAddWithoutValidation(name, value);
            }

            return Task.FromResult(response);
        });
        return this;
    }

    public MockHttp Fail(Exception exception)
    {
        _queue.Enqueue(_ => Task.FromException<HttpResponseMessage>(exception));
        return this;
    }

    public MockHttp Hang()
    {
        _queue.Enqueue(async token =>
        {
            await Task.Delay(Timeout.InfiniteTimeSpan, token);
            throw new InvalidOperationException("unreachable");
        });
        return this;
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var headers = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var (name, values) in request.Headers.NonValidated)
        {
            headers[name.ToLowerInvariant()] = string.Join(", ", values);
        }

        byte[]? body = null;
        if (request.Content is not null)
        {
            foreach (var (name, values) in request.Content.Headers.NonValidated)
            {
                headers[name.ToLowerInvariant()] = string.Join(", ", values);
            }

            body = await request.Content.ReadAsByteArrayAsync(cancellationToken);
        }

        Requests.Add(new RecordedRequest(request.Method, request.RequestUri!, headers, body));
        if (_queue.Count == 0)
        {
            throw new InvalidOperationException($"No response queued for {request.Method} {request.RequestUri}");
        }

        return await _queue.Dequeue()(cancellationToken);
    }
}

public sealed class Harness : IDisposable
{
    public Harness(Noosh24ClientOptions? options = null)
    {
        options ??= new Noosh24ClientOptions();
        Client = new Noosh24Client("nsk_test_123", new HttpClient(Http), options with
        {
            Delay = (wait, _) =>
            {
                Sleeps.Add(wait.TotalSeconds);
                return Task.CompletedTask;
            },
        });
    }

    public MockHttp Http { get; } = new();

    public List<double> Sleeps { get; } = [];

    public Noosh24Client Client { get; }

    public static object Page(object[] items, int total, int limit = 20, int offset = 0) =>
        new { data = new { items, total, limit, offset } };

    public void Dispose() => Client.Dispose();
}
