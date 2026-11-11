using Noosh24.OpenApi;

namespace Noosh24.OpenApi.Tests;

public sealed class WhereTests
{
    [Fact]
    public void BuildsAndOnlyConditions()
    {
        var text = new Where()
            .Eq("category", "Salads")
            .Ne("station", "")
            .Gt("price", 4.75)
            .Lte("prepMinutes", 15)
            .Eq("vegetarian", false)
            .Gte("createdAt", new DateTimeOffset(2026, 11, 1, 18, 0, 0, TimeSpan.FromHours(4)))
            .Lt("price", 20.0)
            .In("id", "7f0c", "O'Neil", 3)
            .ToString();

        Assert.Equal(
            "category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 AND vegetarian = false"
            + " AND createdAt >= '2026-11-01T18:00:00+04:00' AND price < 20 AND id in ('7f0c', 'O''Neil', 3)",
            text);
    }

    [Fact]
    public void FormatsDatesNumbersAndTimes()
    {
        var text = new Where()
            .Lt("visitedOn", new DateOnly(2026, 11, 2))
            .Gte("createdAt", new DateTime(2026, 11, 1, 14, 0, 0, DateTimeKind.Utc))
            .Gt("createdAt", new DateTimeOffset(2026, 11, 1, 14, 0, 0, 500, TimeSpan.Zero))
            .Eq("total", 12.50m)
            .Eq("big", 1e20)
            .In("zone", ["Terrace", "Chef's table"])
            .ToString();

        Assert.Equal(
            "visitedOn < '2026-11-02' AND createdAt >= '2026-11-01T14:00:00+00:00' AND createdAt > '2026-11-01T14:00:00.5+00:00'"
            + " AND total = 12.5 AND big = 100000000000000000000 AND zone in ('Terrace', 'Chef''s table')",
            text);
    }

    [Fact]
    public void EmptyIsEmptyString()
    {
        Assert.Equal(string.Empty, new Where().ToString());
        Assert.Equal(string.Empty, ((Where)"").ToString());
    }

    [Fact]
    public void PlainTextBecomesAWhere()
    {
        Where where = "status = 'served'";

        Assert.Equal("status = 'served' AND total > 10", where.Gt("total", 10).ToString());
    }

    [Fact]
    public void LiteralQuotesValues()
    {
        Assert.Equal("'O''Neil'", Where.Literal("O'Neil"));
        Assert.Equal("true", Where.Literal(true));
        Assert.Equal("-3", Where.Literal(-3L));
    }

    [Fact]
    public void RejectsBadInput()
    {
        Assert.ThrowsAny<ArgumentException>(() => new Where().Eq("price = 1 OR 1", 1));
        Assert.ThrowsAny<ArgumentException>(() => new Where().Eq("", 1));
        Assert.ThrowsAny<ArgumentException>(() => new Where().Eq("1price", 1));
        Assert.ThrowsAny<ArgumentException>(() => new Where().Eq("price\n", 1));
        Assert.ThrowsAny<ArgumentException>(() => new Where().In("id", []));
        Assert.ThrowsAny<ArgumentException>(() => new Where().Gt("price", double.NaN));
        Assert.ThrowsAny<ArgumentException>(() => new Where().Gt("price", double.PositiveInfinity));
        Assert.ThrowsAny<ArgumentException>(() => new Where().Gt("createdAt", new DateTime(2026, 11, 1)));
        Assert.Throws<ArgumentNullException>(() => new Where().Eq("name", (string?)null));
        Assert.Throws<ArgumentNullException>(() => Where.Literal(null));
        Assert.ThrowsAny<ArgumentException>(() => Where.Literal(default));
    }
}
