namespace Noosh24.OpenApi;

public record ListOptions
{
    public int? Limit { get; init; }

    public int? Offset { get; init; }

    public IReadOnlyList<string>? Sort { get; init; }

    public Where? Where { get; init; }
}

public sealed record ProductListOptions : ListOptions
{
    public IReadOnlyList<string>? Expand { get; init; }
}

public static class ProductExpand
{
    public const string ModifierGroups = "modifierGroups";
    public const string Translations = "translations";
}
