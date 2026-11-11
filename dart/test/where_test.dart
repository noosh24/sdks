import 'package:noosh24/noosh24.dart';
import 'package:test/test.dart';

void main() {
  test('builds AND-only conditions', () {
    final text = Where()
        .eq('category', 'Salads')
        .ne('station', '')
        .gt('price', 4.75)
        .lte('prepMinutes', 15)
        .eq('vegetarian', false)
        .gte(
          'createdAt',
          OffsetDateTime(
            DateTime.utc(2026, 11, 1, 14),
            const Duration(hours: 4),
          ),
        )
        .lt('price', 20.0)
        .isIn('id', ['7f0c', "O'Neil", 3])
        .toString();

    expect(
      text,
      "category = 'Salads' AND station != '' AND price > 4.75 AND "
      'prepMinutes <= 15 AND vegetarian = false AND '
      "createdAt >= '2026-11-01T18:00:00+04:00' AND price < 20 AND "
      "id in ('7f0c', 'O''Neil', 3)",
    );
  });

  test('quotes UTC date-times, fractions and plain dates', () {
    expect(
      Where.literal(DateTime.utc(2026, 11, 1, 14, 0, 0, 250)),
      "'2026-11-01T14:00:00.250Z'",
    );
    expect(
      Where.literal(DateTime.utc(2026, 11, 1, 14, 0, 0, 0, 5)),
      "'2026-11-01T14:00:00.000005Z'",
    );
    expect(
      Where.literal(
        OffsetDateTime(
          DateTime.utc(2026, 11, 1, 2, 30),
          const Duration(hours: -3, minutes: -30),
        ),
      ),
      "'2026-10-31T23:00:00-03:30'",
    );
    expect(Where.literal(CalendarDate(2026, 11, 2)), "'2026-11-02'");
    expect(
      Where().lt('visitedOn', CalendarDate.parse('2026-11-02')).toString(),
      "visitedOn < '2026-11-02'",
    );
  });

  test('a local DateTime carries its own offset', () {
    final local = DateTime(2026, 11, 1, 18);
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final minutes = offset.inMinutes.abs();
    final zone = offset == Duration.zero
        ? 'Z'
        : '$sign${'${minutes ~/ 60}'.padLeft(2, '0')}:'
              '${'${minutes % 60}'.padLeft(2, '0')}';
    expect(Where.literal(local), "'2026-11-01T18:00:00$zone'");
  });

  test('is empty with no conditions', () {
    expect(Where().toString(), '');
    expect(Where().isEmpty, isTrue);
  });

  test('rejects bad input', () {
    expect(() => Where().eq('price = 1 OR 1', 1), throwsArgumentError);
    expect(() => Where().isIn('id', []), throwsArgumentError);
    expect(() => Where().gt('price', double.nan), throwsArgumentError);
    expect(() => Where().gt('price', double.infinity), throwsArgumentError);
    expect(() => Where.literal(null), throwsArgumentError);
    expect(() => Where().eq('id', <String>[]), throwsArgumentError);
    expect(() => CalendarDate(2026, 2, 30), throwsArgumentError);
    expect(() => CalendarDate.parse('20-11-2026'), throwsFormatException);
  });
}
