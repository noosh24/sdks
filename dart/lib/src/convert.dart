final _fraction = RegExp(r'\.(\d+)');
final _zone = RegExp(r'(?:[Zz]|[+-]\d{2}(?::?\d{2})?)$');
final _dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');

Map<String, dynamic>? asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return {for (final entry in value.entries) '${entry.key}': entry.value};
  }
  return null;
}

String? readString(Object? value) {
  if (value == null || value is Map || value is List) {
    return null;
  }
  return value is String ? value : '$value';
}

int? readInt(Object? value) => value is num ? value.toInt() : null;

double? readDouble(Object? value) => value is num ? value.toDouble() : null;

bool? readBool(Object? value) => value is bool ? value : null;

DateTime? readDateTime(Object? value) {
  if (value is! String) {
    return null;
  }
  var text = value.trim();
  if (text.isEmpty) {
    return null;
  }
  if (_dateOnly.hasMatch(text)) {
    text = '${text}T00:00:00Z';
  } else if (!_zone.hasMatch(text)) {
    text = '${text}Z';
  }
  text = text.replaceFirstMapped(
    _fraction,
    (m) => '.${'${m[1]}000000'.substring(0, 6)}',
  );
  return DateTime.tryParse(text)?.toUtc();
}

List<String> readStrings(Object? value) {
  if (value is! List) {
    return const [];
  }
  return List.unmodifiable([
    for (final item in value)
      if (item != null && item is! Map && item is! List) readString(item)!,
  ]);
}

Map<String, double> readDoubles(Object? value) {
  final map = asJsonMap(value);
  if (map == null) {
    return const {};
  }
  return Map.unmodifiable({
    for (final entry in map.entries)
      if (entry.value is num) entry.key: (entry.value as num).toDouble(),
  });
}

T? readObject<T>(Object? value, T Function(Map<String, dynamic>) factory) {
  final map = asJsonMap(value);
  return map == null ? null : factory(map);
}

List<T> readList<T>(Object? value, T Function(Map<String, dynamic>) factory) {
  if (value is! List) {
    return const [];
  }
  return List.unmodifiable([
    for (final item in value)
      if (asJsonMap(item) case final map?) factory(map),
  ]);
}

Map<String, T> readMap<T>(
  Object? value,
  T Function(Map<String, dynamic>) factory,
) {
  final map = asJsonMap(value);
  if (map == null) {
    return const {};
  }
  return Map.unmodifiable({
    for (final entry in map.entries)
      if (asJsonMap(entry.value) case final item?) entry.key: factory(item),
  });
}
