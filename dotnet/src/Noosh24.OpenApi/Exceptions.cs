namespace Noosh24.OpenApi;

public class Noosh24Exception : Exception
{
    public Noosh24Exception()
    {
    }

    public Noosh24Exception(string message)
        : base(message)
    {
    }

    public Noosh24Exception(string message, Exception? innerException)
        : base(message, innerException)
    {
    }
}

public class ApiConnectionException : Noosh24Exception
{
    public ApiConnectionException()
    {
    }

    public ApiConnectionException(string message)
        : base(message)
    {
    }

    public ApiConnectionException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }
}

public class ApiTimeoutException : ApiConnectionException
{
    public ApiTimeoutException()
    {
    }

    public ApiTimeoutException(string message)
        : base(message)
    {
    }

    public ApiTimeoutException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }
}

public class ApiException : Noosh24Exception
{
    private static readonly IReadOnlyDictionary<string, string> NoHeaders = new Dictionary<string, string>();

    public ApiException()
        : this(0, null, "Noosh24 API error")
    {
    }

    public ApiException(string message)
        : this(0, null, message)
    {
    }

    public ApiException(string message, Exception? innerException)
        : base(message, innerException)
    {
        Headers = NoHeaders;
        Body = string.Empty;
    }

    public ApiException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(message)
    {
        Status = status;
        Code = code;
        Headers = headers is null ? NoHeaders : LowerCase(headers);
        Body = body ?? string.Empty;
    }

    public int Status { get; }

    public string? Code { get; }

    public IReadOnlyDictionary<string, string> Headers { get; }

    public string Body { get; }

    private static Dictionary<string, string> LowerCase(IReadOnlyDictionary<string, string> headers)
    {
        var lower = new Dictionary<string, string>(headers.Count, StringComparer.Ordinal);
        foreach (var (name, value) in headers)
        {
            lower[name.ToLowerInvariant()] = value;
        }

        return lower;
    }

    internal static ApiException FromResponse(int status, IReadOnlyDictionary<string, string> headers, string body)
    {
        string? code = null;
        var message = string.Empty;
        try
        {
            using var document = System.Text.Json.JsonDocument.Parse(body);
            if (document.RootElement.ValueKind == System.Text.Json.JsonValueKind.Object)
            {
                if (document.RootElement.TryGetProperty("error", out var error) && error.ValueKind == System.Text.Json.JsonValueKind.String)
                {
                    code = error.GetString();
                }

                if (document.RootElement.TryGetProperty("message", out var text) && text.ValueKind == System.Text.Json.JsonValueKind.String)
                {
                    message = text.GetString() ?? string.Empty;
                }
            }
        }
        catch (System.Text.Json.JsonException)
        {
        }

        if (message.Length == 0)
        {
            message = string.IsNullOrEmpty(code) ? $"HTTP {status}" : code;
        }

        return code switch
        {
            "validation_error" => new ValidationException(status, code, message, headers, body),
            "no_api_key" => new NoApiKeyException(status, code, message, headers, body),
            "invalid_api_key" => new InvalidApiKeyException(status, code, message, headers, body),
            "insufficient_scope" => new InsufficientScopeException(status, code, message, headers, body),
            "module_not_enabled" => new ModuleNotEnabledException(status, code, message, headers, body),
            "venue_suspended" => new VenueSuspendedException(status, code, message, headers, body),
            "not_your_reservation" => new NotYourReservationException(status, code, message, headers, body),
            "not_found" => new NotFoundException(status, code, message, headers, body),
            "table_not_found" => new TableNotFoundException(status, code, message, headers, body),
            "table_taken" => new TableTakenException(status, code, message, headers, body),
            "cannot_cancel" => new CannotCancelException(status, code, message, headers, body),
            "outside_hours" => new OutsideHoursException(status, code, message, headers, body),
            "in_the_past" => new InThePastException(status, code, message, headers, body),
            "table_too_small" => new TableTooSmallException(status, code, message, headers, body),
            "rate_limit_exceeded" => new RateLimitException(status, code, message, headers, body),
            "temporarily_unavailable" => new TemporarilyUnavailableException(status, code, message, headers, body),
            _ => status switch
            {
                400 => new ValidationException(status, code, message, headers, body),
                401 => new AuthenticationException(status, code, message, headers, body),
                403 => new PermissionDeniedException(status, code, message, headers, body),
                404 => new NotFoundException(status, code, message, headers, body),
                409 => new ConflictException(status, code, message, headers, body),
                422 => new UnprocessableException(status, code, message, headers, body),
                429 => new RateLimitException(status, code, message, headers, body),
                >= 500 => new ServerException(status, code, message, headers, body),
                _ => new ApiException(status, code, message, headers, body),
            },
        };
    }
}

public sealed class ValidationException : ApiException
{
    public ValidationException()
    {
    }

    public ValidationException(string message)
        : base(message)
    {
    }

    public ValidationException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public ValidationException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public class AuthenticationException : ApiException
{
    public AuthenticationException()
    {
    }

    public AuthenticationException(string message)
        : base(message)
    {
    }

    public AuthenticationException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public AuthenticationException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class NoApiKeyException : AuthenticationException
{
    public NoApiKeyException()
    {
    }

    public NoApiKeyException(string message)
        : base(message)
    {
    }

    public NoApiKeyException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public NoApiKeyException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class InvalidApiKeyException : AuthenticationException
{
    public InvalidApiKeyException()
    {
    }

    public InvalidApiKeyException(string message)
        : base(message)
    {
    }

    public InvalidApiKeyException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public InvalidApiKeyException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public class PermissionDeniedException : ApiException
{
    public PermissionDeniedException()
    {
    }

    public PermissionDeniedException(string message)
        : base(message)
    {
    }

    public PermissionDeniedException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public PermissionDeniedException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class InsufficientScopeException : PermissionDeniedException
{
    public InsufficientScopeException()
    {
    }

    public InsufficientScopeException(string message)
        : base(message)
    {
    }

    public InsufficientScopeException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public InsufficientScopeException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class ModuleNotEnabledException : PermissionDeniedException
{
    public ModuleNotEnabledException()
    {
    }

    public ModuleNotEnabledException(string message)
        : base(message)
    {
    }

    public ModuleNotEnabledException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public ModuleNotEnabledException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class VenueSuspendedException : PermissionDeniedException
{
    public VenueSuspendedException()
    {
    }

    public VenueSuspendedException(string message)
        : base(message)
    {
    }

    public VenueSuspendedException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public VenueSuspendedException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class NotYourReservationException : PermissionDeniedException
{
    public NotYourReservationException()
    {
    }

    public NotYourReservationException(string message)
        : base(message)
    {
    }

    public NotYourReservationException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public NotYourReservationException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public class NotFoundException : ApiException
{
    public NotFoundException()
    {
    }

    public NotFoundException(string message)
        : base(message)
    {
    }

    public NotFoundException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public NotFoundException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class TableNotFoundException : NotFoundException
{
    public TableNotFoundException()
    {
    }

    public TableNotFoundException(string message)
        : base(message)
    {
    }

    public TableNotFoundException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public TableNotFoundException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public class ConflictException : ApiException
{
    public ConflictException()
    {
    }

    public ConflictException(string message)
        : base(message)
    {
    }

    public ConflictException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public ConflictException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class TableTakenException : ConflictException
{
    public TableTakenException()
    {
    }

    public TableTakenException(string message)
        : base(message)
    {
    }

    public TableTakenException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public TableTakenException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class CannotCancelException : ConflictException
{
    public CannotCancelException()
    {
    }

    public CannotCancelException(string message)
        : base(message)
    {
    }

    public CannotCancelException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public CannotCancelException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public class UnprocessableException : ApiException
{
    public UnprocessableException()
    {
    }

    public UnprocessableException(string message)
        : base(message)
    {
    }

    public UnprocessableException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public UnprocessableException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class OutsideHoursException : UnprocessableException
{
    public OutsideHoursException()
    {
    }

    public OutsideHoursException(string message)
        : base(message)
    {
    }

    public OutsideHoursException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public OutsideHoursException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class InThePastException : UnprocessableException
{
    public InThePastException()
    {
    }

    public InThePastException(string message)
        : base(message)
    {
    }

    public InThePastException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public InThePastException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class TableTooSmallException : UnprocessableException
{
    public TableTooSmallException()
    {
    }

    public TableTooSmallException(string message)
        : base(message)
    {
    }

    public TableTooSmallException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public TableTooSmallException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class RateLimitException : ApiException
{
    public RateLimitException()
    {
    }

    public RateLimitException(string message)
        : base(message)
    {
    }

    public RateLimitException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public RateLimitException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }

    public int? RetryAfter
    {
        get
        {
            if (!Headers.TryGetValue("retry-after", out var value))
            {
                return null;
            }

            if (!double.TryParse(value.Trim(), System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var seconds) || !double.IsFinite(seconds))
            {
                return null;
            }

            return seconds <= 0 ? 0 : seconds >= int.MaxValue ? int.MaxValue : (int)seconds;
        }
    }
}

public class ServerException : ApiException
{
    public ServerException()
    {
    }

    public ServerException(string message)
        : base(message)
    {
    }

    public ServerException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public ServerException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}

public sealed class TemporarilyUnavailableException : ServerException
{
    public TemporarilyUnavailableException()
    {
    }

    public TemporarilyUnavailableException(string message)
        : base(message)
    {
    }

    public TemporarilyUnavailableException(string message, Exception? innerException)
        : base(message, innerException)
    {
    }

    public TemporarilyUnavailableException(int status, string? code, string message, IReadOnlyDictionary<string, string>? headers = null, string? body = null)
        : base(status, code, message, headers, body)
    {
    }
}
