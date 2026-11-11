using System.Globalization;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.Json.Serialization.Metadata;
using System.Text.RegularExpressions;

namespace Noosh24.OpenApi;

internal static partial class Json
{
    public static readonly Noosh24JsonContext Context = new(new JsonSerializerOptions
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
        Converters = { new Rfc3339Converter(), new HourMinuteConverter() },
    });

    public static T Model<T>(int status, JsonElement data, JsonTypeInfo<T> info)
    {
        try
        {
            var value = data.ValueKind == JsonValueKind.Object ? data.Deserialize(info) : JsonSerializer.Deserialize("{}"u8, info);
            return value ?? throw new JsonException("null model");
        }
        catch (JsonException exception)
        {
            throw new ApiException(status, null, "The API answered with a body the client could not read: " + exception.Message, null, data.ValueKind == JsonValueKind.Undefined ? string.Empty : data.GetRawText());
        }
    }

    public static List<T> Items<T>(int status, JsonElement data, JsonTypeInfo<T> info)
    {
        var items = new List<T>();
        if (data.ValueKind == JsonValueKind.Object && data.TryGetProperty("items", out var array) && array.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in array.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.Object)
                {
                    items.Add(Model(status, item, info));
                }
            }
        }

        return items;
    }

    public static int? Int(JsonElement data, string name)
    {
        if (data.ValueKind != JsonValueKind.Object || !data.TryGetProperty(name, out var value) || value.ValueKind != JsonValueKind.Number)
        {
            return null;
        }

        if (value.TryGetInt32(out var integer))
        {
            return integer;
        }

        return value.TryGetDouble(out var number) && double.IsFinite(number) ? (int)Math.Clamp(number, int.MinValue, int.MaxValue) : null;
    }

    public static DateTimeOffset? ParseTimestamp(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return null;
        }

        var trimmed = Fraction().Replace(text.Trim(), match => match.Groups[1].Value.Length > 7 ? "." + match.Groups[1].Value[..7] : match.Value, 1);
        return DateTimeOffset.TryParse(trimmed, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var parsed) ? parsed : null;
    }

    [GeneratedRegex(@"\.(\d+)", RegexOptions.CultureInvariant)]
    private static partial Regex Fraction();
}

internal sealed class Rfc3339Converter : JsonConverter<DateTimeOffset?>
{
    public override bool HandleNull => true;

    public override DateTimeOffset? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.String)
        {
            return Json.ParseTimestamp(reader.GetString());
        }

        reader.Skip();
        return null;
    }

    public override void Write(Utf8JsonWriter writer, DateTimeOffset? value, JsonSerializerOptions options)
    {
        if (value is { } moment)
        {
            writer.WriteStringValue(moment.ToString("yyyy-MM-dd'T'HH:mm:ss.FFFFFFFK", CultureInfo.InvariantCulture));
        }
        else
        {
            writer.WriteNullValue();
        }
    }
}

internal sealed class HourMinuteConverter : JsonConverter<TimeOnly>
{
    public override TimeOnly Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
        TimeOnly.Parse(reader.GetString() ?? string.Empty, CultureInfo.InvariantCulture);

    public override void Write(Utf8JsonWriter writer, TimeOnly value, JsonSerializerOptions options) =>
        writer.WriteStringValue(value.ToString("HH:mm", CultureInfo.InvariantCulture));
}
