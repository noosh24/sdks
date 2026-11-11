import 'dates.dart';

final _field = RegExp(r'^[A-Za-z][A-Za-z0-9_.]*$');

class Where {
  final List<String> _conditions = [];

  Where eq(String field, Object value) => _add(field, '=', value);

  Where ne(String field, Object value) => _add(field, '!=', value);

  Where gt(String field, Object value) => _add(field, '>', value);

  Where gte(String field, Object value) => _add(field, '>=', value);

  Where lt(String field, Object value) => _add(field, '<', value);

  Where lte(String field, Object value) => _add(field, '<=', value);

  Where isIn(String field, Iterable<Object> values) {
    final items = values.toList();
    if (items.isEmpty) {
      throw ArgumentError.value(
        values,
        'values',
        'isIn() needs at least one value',
      );
    }
    _conditions.add(
      '${_checkField(field)} in (${items.map(literal).join(', ')})',
    );
    return this;
  }

  bool get isEmpty => _conditions.isEmpty;

  @override
  String toString() => _conditions.join(' AND ');

  static String literal(Object? value) {
    switch (value) {
      case null:
        throw ArgumentError.notNull('value');
      case bool():
        return value ? 'true' : 'false';
      case int():
        return '$value';
      case double():
        if (!value.isFinite) {
          throw ArgumentError.value(
            value,
            'value',
            'Numbers in where must be finite',
          );
        }
        return value == value.truncateToDouble() && value.abs() < 1e15
            ? '${value.toInt()}'
            : '$value';
      case String():
        return "'${value.replaceAll("'", "''")}'";
      case OffsetDateTime():
        return "'${value.toIso8601String()}'";
      case DateTime():
        return "'${rfc3339(value, value.isUtc ? Duration.zero : value.timeZoneOffset)}'";
      case CalendarDate():
        return "'$value'";
      default:
        throw ArgumentError.value(
          value,
          'value',
          'where takes strings, numbers, booleans, DateTime, OffsetDateTime and CalendarDate',
        );
    }
  }

  Where _add(String field, String operator, Object value) {
    _conditions.add('${_checkField(field)} $operator ${literal(value)}');
    return this;
  }
}

String _checkField(String field) {
  if (!_field.hasMatch(field)) {
    throw ArgumentError.value(field, 'field', 'Not a field name');
  }
  return field;
}
