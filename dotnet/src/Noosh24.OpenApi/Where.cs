using System.Globalization;
using System.Text.RegularExpressions;

namespace Noosh24.OpenApi;

public sealed partial class Where
{
    private readonly List<string> _conditions = [];

    public Where()
    {
    }

    public Where(string text)
    {
        if (!string.IsNullOrEmpty(text))
        {
            _conditions.Add(text);
        }
    }

    public static implicit operator Where(string text) => new(text);

    public static Where FromString(string text) => new(text);

    public Where Eq(string field, WhereValue value) => Add(field, "=", value);

    public Where Ne(string field, WhereValue value) => Add(field, "!=", value);

    public Where Gt(string field, WhereValue value) => Add(field, ">", value);

    public Where Gte(string field, WhereValue value) => Add(field, ">=", value);

    public Where Lt(string field, WhereValue value) => Add(field, "<", value);

    public Where Lte(string field, WhereValue value) => Add(field, "<=", value);

    public Where In(string field, params IEnumerable<WhereValue> values)
    {
        ArgumentNullException.ThrowIfNull(values);
        var name = Field(field);
        var literals = values.Select(Literal).ToList();
        if (literals.Count == 0)
        {
            throw new ArgumentException("In() needs at least one value", nameof(values));
        }

        _conditions.Add($"{name} in ({string.Join(", ", literals)})");
        return this;
    }

    public override string ToString() => string.Join(" AND ", _conditions);

    public static string Literal(WhereValue value) => value.ToLiteral();

    private Where Add(string field, string op, WhereValue value)
    {
        var name = Field(field);
        _conditions.Add($"{name} {op} {Literal(value)}");
        return this;
    }

    private static string Field(string field)
    {
        if (field is null || !FieldPattern().IsMatch(field))
        {
            throw new ArgumentException($"\"{field}\" is not a field name", nameof(field));
        }

        return field;
    }

    [GeneratedRegex(@"\A[A-Za-z][A-Za-z0-9_.]*\z", RegexOptions.CultureInvariant)]
    private static partial Regex FieldPattern();
}

public readonly struct WhereValue : IEquatable<WhereValue>
{
    private enum Kind
    {
        None,
        Null,
        String,
        Integer,
        Double,
        Decimal,
        Boolean,
        DateTimeOffset,
        DateTime,
        Date,
    }

    private readonly Kind _kind;
    private readonly string? _string;
    private readonly long _integer;
    private readonly double _double;
    private readonly decimal _decimal;
    private readonly DateTimeOffset _dateTimeOffset;
    private readonly DateTime _dateTime;
    private readonly DateOnly _date;

    private WhereValue(Kind kind, string? text = null, long integer = 0, double number = 0, decimal money = 0, DateTimeOffset moment = default, DateTime local = default, DateOnly date = default)
    {
        _kind = kind;
        _string = text;
        _integer = integer;
        _double = number;
        _decimal = money;
        _dateTimeOffset = moment;
        _dateTime = local;
        _date = date;
    }

    public static implicit operator WhereValue(string? value) => value is null ? new(Kind.Null) : new(Kind.String, text: value);

    public static implicit operator WhereValue(int value) => new(Kind.Integer, integer: value);

    public static implicit operator WhereValue(long value) => new(Kind.Integer, integer: value);

    public static implicit operator WhereValue(double value) => new(Kind.Double, number: value);

    public static implicit operator WhereValue(decimal value) => new(Kind.Decimal, money: value);

    public static implicit operator WhereValue(bool value) => new(Kind.Boolean, integer: value ? 1 : 0);

    public static implicit operator WhereValue(DateTimeOffset value) => new(Kind.DateTimeOffset, moment: value);

    public static implicit operator WhereValue(DateTime value) => new(Kind.DateTime, local: value);

    public static implicit operator WhereValue(DateOnly value) => new(Kind.Date, date: value);

    public static WhereValue FromString(string? value) => value;

    public static WhereValue FromInt64(long value) => value;

    public static WhereValue FromDouble(double value) => value;

    public static WhereValue FromDecimal(decimal value) => value;

    public static WhereValue FromBoolean(bool value) => value;

    public static WhereValue FromDateTimeOffset(DateTimeOffset value) => value;

    public static WhereValue FromDateTime(DateTime value) => value;

    public static WhereValue FromDateOnly(DateOnly value) => value;

    internal string ToLiteral() => _kind switch
    {
        Kind.String => "'" + _string!.Replace("'", "''", StringComparison.Ordinal) + "'",
        Kind.Integer => _integer.ToString(CultureInfo.InvariantCulture),
        Kind.Double => Number(_double),
        Kind.Decimal => _decimal.ToString("G29", CultureInfo.InvariantCulture),
        Kind.Boolean => _integer == 1 ? "true" : "false",
        Kind.DateTimeOffset => Moment(_dateTimeOffset),
        Kind.DateTime => _dateTime.Kind == DateTimeKind.Unspecified
            ? throw new ArgumentException("where needs a DateTime with a known kind (Utc or Local), or a DateTimeOffset")
            : Moment(new DateTimeOffset(_dateTime)),
        Kind.Date => "'" + _date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) + "'",
        Kind.Null => throw new ArgumentNullException(null, "where takes no null values"),
        _ => throw new ArgumentException("where takes strings, numbers, booleans and dates"),
    };

    public bool Equals(WhereValue other) => _kind == other._kind
        && string.Equals(_string, other._string, StringComparison.Ordinal)
        && _integer == other._integer
        && _double.Equals(other._double)
        && _decimal == other._decimal
        && _dateTimeOffset.Equals(other._dateTimeOffset)
        && _dateTime.Equals(other._dateTime)
        && _date == other._date;

    public override bool Equals(object? obj) => obj is WhereValue other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(_kind, _string, _integer, _double, _decimal, _dateTimeOffset, _dateTime, _date);

    public static bool operator ==(WhereValue left, WhereValue right) => left.Equals(right);

    public static bool operator !=(WhereValue left, WhereValue right) => !left.Equals(right);

    private static string Number(double value)
    {
        if (!double.IsFinite(value))
        {
            throw new ArgumentOutOfRangeException(nameof(value), "Numbers in where must be finite");
        }

        return value == Math.Truncate(value)
            ? value.ToString("F0", CultureInfo.InvariantCulture)
            : value.ToString("R", CultureInfo.InvariantCulture);
    }

    private static string Moment(DateTimeOffset value) =>
        "'" + value.ToString("yyyy-MM-dd'T'HH:mm:ss.FFFFFFFzzz", CultureInfo.InvariantCulture) + "'";
}
