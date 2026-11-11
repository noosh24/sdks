using System.Collections;

namespace Noosh24.OpenApi;

public sealed class Page<T> : IReadOnlyList<T>
{
    public Page(IReadOnlyList<T> items, int total, int limit, int offset)
    {
        ArgumentNullException.ThrowIfNull(items);
        Items = items;
        Total = total;
        Limit = limit;
        Offset = offset;
    }

    public IReadOnlyList<T> Items { get; }

    public int Total { get; }

    public int Limit { get; }

    public int Offset { get; }

    public bool HasMore => Items.Count > 0 && Offset + Items.Count < Total;

    public int NextOffset => Offset + Items.Count;

    public int Count => Items.Count;

    public T this[int index] => Items[index];

    public IEnumerator<T> GetEnumerator() => Items.GetEnumerator();

    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}
