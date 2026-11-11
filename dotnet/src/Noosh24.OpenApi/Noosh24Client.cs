using System.Globalization;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace Noosh24.OpenApi;

public sealed class Noosh24Client : IDisposable
{
    public const string DefaultBaseUrl = "https://open-api.noosh24.com/v1";

    public const string Version = "0.1.0";

    private static readonly TimeSpan MaxRetryWait = TimeSpan.FromSeconds(60);

    private readonly string _apiKey;
    private readonly string _baseUrl;
    private readonly TimeSpan _timeout;
    private readonly int _maxRetries;
    private readonly string _userAgent;
    private readonly HttpClient _http;
    private readonly bool _ownsHttp;
    private readonly Func<TimeSpan, CancellationToken, Task> _delay;
    private bool _disposed;

    public Noosh24Client(string apiKey, Noosh24ClientOptions? options = null)
        : this(apiKey, null, options)
    {
    }

    public Noosh24Client(string apiKey, HttpClient? httpClient, Noosh24ClientOptions? options = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(apiKey);
        options ??= new Noosh24ClientOptions();
        if (options.Timeout <= TimeSpan.Zero && options.Timeout != System.Threading.Timeout.InfiniteTimeSpan)
        {
            throw new ArgumentOutOfRangeException(nameof(options), "Timeout must be positive");
        }

        _apiKey = apiKey.Trim();
        _baseUrl = (string.IsNullOrWhiteSpace(options.BaseUrl) ? DefaultBaseUrl : options.BaseUrl).TrimEnd('/');
        _timeout = options.Timeout;
        _maxRetries = Math.Max(0, options.MaxRetries);
        var agent = "noosh24-dotnet/" + Version;
        _userAgent = string.IsNullOrWhiteSpace(options.UserAgent) ? agent : options.UserAgent + " " + agent;
        _delay = options.Delay ?? Task.Delay;
        _ownsHttp = httpClient is null;
        _http = httpClient ?? new HttpClient(new SocketsHttpHandler
        {
            AllowAutoRedirect = false,
            PooledConnectionLifetime = TimeSpan.FromMinutes(5),
        })
        {
            Timeout = System.Threading.Timeout.InfiniteTimeSpan,
        };

        Menu = new Menu(this);
        Reservations = new Reservations(this);
        Orders = new Orders(this);
        Payments = new Payments(this);
        Tables = new Tables(this);
        Customers = new Customers(this);
        Loyalty = new Loyalty(this);
        Stock = new Stock(this);
        Reviews = new Reviews(this);
    }

    public Menu Menu { get; }

    public Reservations Reservations { get; }

    public Orders Orders { get; }

    public Payments Payments { get; }

    public Tables Tables { get; }

    public Customers Customers { get; }

    public Loyalty Loyalty { get; }

    public Stock Stock { get; }

    public Reviews Reviews { get; }

    public async Task<Whoami> WhoamiAsync(CancellationToken cancellationToken = default)
    {
        var response = await SendAsync(HttpMethod.Get, "/whoami", null, null, true, cancellationToken).ConfigureAwait(false);
        return Json.Model(response.Status, response.Data, Json.Context.Whoami);
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        if (_ownsHttp)
        {
            _http.Dispose();
        }
    }

    internal async Task<ApiResponse> SendAsync(HttpMethod method, string path, IReadOnlyList<KeyValuePair<string, string>>? query, byte[]? body, bool retryable, CancellationToken cancellationToken)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        var url = new Uri(_baseUrl + path + QueryString(query));
        for (var attempt = 0; ; attempt++)
        {
            using var request = new HttpRequestMessage(method, url);
            request.Headers.TryAddWithoutValidation("Authorization", "Bearer " + _apiKey);
            request.Headers.TryAddWithoutValidation("Accept", "application/json");
            request.Headers.TryAddWithoutValidation("User-Agent", _userAgent);
            if (body is not null)
            {
                request.Content = new ByteArrayContent(body);
                request.Content.Headers.ContentType = new MediaTypeHeaderValue("application/json");
            }

            int status;
            Dictionary<string, string> headers;
            string text;
            using (var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken))
            {
                if (_timeout != System.Threading.Timeout.InfiniteTimeSpan)
                {
                    timeout.CancelAfter(_timeout);
                }

                try
                {
                    using var response = await _http.SendAsync(request, HttpCompletionOption.ResponseContentRead, timeout.Token).ConfigureAwait(false);
                    status = (int)response.StatusCode;
                    headers = Headers(response);
                    text = await response.Content.ReadAsStringAsync(timeout.Token).ConfigureAwait(false);
                }
                catch (OperationCanceledException exception) when (!cancellationToken.IsCancellationRequested)
                {
                    if (retryable && attempt < _maxRetries)
                    {
                        await _delay(Backoff(attempt), cancellationToken).ConfigureAwait(false);
                        continue;
                    }

                    throw new ApiTimeoutException($"Request timed out after {_timeout.TotalSeconds.ToString(CultureInfo.InvariantCulture)} s", exception);
                }
                catch (Exception exception) when (exception is HttpRequestException or IOException)
                {
                    if (retryable && attempt < _maxRetries)
                    {
                        await _delay(Backoff(attempt), cancellationToken).ConfigureAwait(false);
                        continue;
                    }

                    throw new ApiConnectionException("Could not reach the Noosh24 API: " + exception.Message, exception);
                }
            }

            if (status is >= 200 and < 300)
            {
                return new ApiResponse(status, Decode(status, headers, text));
            }

            var wait = RetryWait(status, headers, attempt);
            if (retryable && attempt < _maxRetries && wait is { } delay)
            {
                await _delay(delay, cancellationToken).ConfigureAwait(false);
                continue;
            }

            throw ApiException.FromResponse(status, headers, text);
        }
    }

    internal static string QueryString(IReadOnlyList<KeyValuePair<string, string>>? query)
    {
        if (query is null || query.Count == 0)
        {
            return string.Empty;
        }

        var builder = new StringBuilder();
        foreach (var (name, value) in query)
        {
            builder.Append(builder.Length == 0 ? '?' : '&');
            builder.Append(Uri.EscapeDataString(name)).Append('=').Append(Uri.EscapeDataString(value));
        }

        return builder.ToString();
    }

    private static Dictionary<string, string> Headers(HttpResponseMessage response)
    {
        var headers = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var (name, values) in response.Headers.Concat(response.Content.Headers))
        {
            headers[name.ToLowerInvariant()] = string.Join(", ", values);
        }

        return headers;
    }

    private static JsonElement Decode(int status, Dictionary<string, string> headers, string text)
    {
        if (text.Length == 0)
        {
            return default;
        }

        JsonDocument document;
        try
        {
            document = JsonDocument.Parse(text);
        }
        catch (JsonException)
        {
            throw new ApiException(status, null, "The API answered with a body that is not JSON", headers, text);
        }

        using (document)
        {
            if (document.RootElement.ValueKind != JsonValueKind.Object || !document.RootElement.TryGetProperty("data", out var data))
            {
                throw new ApiException(status, null, "The API answered without a \"data\" field", headers, text);
            }

            return data.Clone();
        }
    }

    private static TimeSpan? RetryWait(int status, Dictionary<string, string> headers, int attempt)
    {
        if (status is not (429 or 502 or 503 or 504))
        {
            return null;
        }

        if (headers.TryGetValue("retry-after", out var header)
            && double.TryParse(header.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var seconds)
            && double.IsFinite(seconds))
        {
            var wait = TimeSpan.FromSeconds(Math.Max(0, Math.Min(seconds, MaxRetryWait.TotalSeconds + 1)));
            return wait <= MaxRetryWait ? wait : null;
        }

        return Backoff(attempt);
    }

    private static TimeSpan Backoff(int attempt) => TimeSpan.FromSeconds(Math.Min(8, 0.5 * Math.Pow(2, attempt)));
}

internal readonly record struct ApiResponse(int Status, JsonElement Data);
