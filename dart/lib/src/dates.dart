final _calendarDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

final class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(this.year, this.month, this.day) {
    final check = DateTime.utc(year, month, day);
    if (year < 0 ||
        year > 9999 ||
        check.year != year ||
        check.month != month ||
        check.day != day) {
      throw ArgumentError('$year-$month-$day is not a calendar date');
    }
  }

  factory CalendarDate.fromDateTime(DateTime value) =>
      CalendarDate(value.year, value.month, value.day);

  factory CalendarDate.parse(String text) {
    final match = _calendarDate.firstMatch(text.trim());
    if (match == null) {
      throw FormatException('Expected a YYYY-MM-DD date', text);
    }
    return CalendarDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  final int year;
  final int month;
  final int day;

  @override
  int compareTo(CalendarDate other) =>
      (year - other.year) * 10000 +
      (month - other.month) * 100 +
      (day - other.day);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';
}

final class OffsetDateTime {
  OffsetDateTime(DateTime instant, this.offset) : instant = instant.toUtc() {
    if (offset.inMicroseconds % Duration.microsecondsPerMinute != 0 ||
        offset.abs() >= const Duration(hours: 24)) {
      throw ArgumentError.value(offset, 'offset', 'Not a UTC offset');
    }
  }

  final DateTime instant;
  final Duration offset;

  String toIso8601String() => rfc3339(instant.add(offset), offset);

  @override
  bool operator ==(Object other) =>
      other is OffsetDateTime &&
      other.instant == instant &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(instant, offset);

  @override
  String toString() => toIso8601String();
}

String rfc3339(DateTime wall, Duration offset) {
  final buffer = StringBuffer()
    ..write(_pad(wall.year, 4))
    ..write('-')
    ..write(_pad(wall.month, 2))
    ..write('-')
    ..write(_pad(wall.day, 2))
    ..write('T')
    ..write(_pad(wall.hour, 2))
    ..write(':')
    ..write(_pad(wall.minute, 2))
    ..write(':')
    ..write(_pad(wall.second, 2));
  if (wall.microsecond != 0) {
    buffer
      ..write('.')
      ..write(_pad(wall.millisecond, 3))
      ..write(_pad(wall.microsecond, 3));
  } else if (wall.millisecond != 0) {
    buffer
      ..write('.')
      ..write(_pad(wall.millisecond, 3));
  }
  if (offset == Duration.zero) {
    buffer.write('Z');
  } else {
    final minutes = offset.inMinutes.abs();
    buffer
      ..write(offset.isNegative ? '-' : '+')
      ..write(_pad(minutes ~/ 60, 2))
      ..write(':')
      ..write(_pad(minutes % 60, 2));
  }
  return buffer.toString();
}

String _pad(int value, int width) => value.toString().padLeft(width, '0');
