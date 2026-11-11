final class Page<T> {
  Page({
    required List<T> items,
    required this.total,
    required this.limit,
    required this.offset,
  }) : items = List.unmodifiable(items);

  final List<T> items;
  final int total;
  final int limit;
  final int offset;

  bool get hasMore => items.isNotEmpty && offset + items.length < total;

  int get nextOffset => offset + items.length;
}
