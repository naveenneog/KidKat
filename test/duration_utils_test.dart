import 'package:flutter_test/flutter_test.dart';
import 'package:kidkat/core/duration_utils.dart';

void main() {
  group('parseIsoDurationSeconds', () {
    test('parses minutes and seconds', () {
      expect(parseIsoDurationSeconds('PT1M30S'), 90);
    });
    test('parses seconds only', () {
      expect(parseIsoDurationSeconds('PT45S'), 45);
    });
    test('parses hours, minutes, seconds', () {
      expect(parseIsoDurationSeconds('PT1H2M3S'), 3723);
    });
    test('parses minutes only', () {
      expect(parseIsoDurationSeconds('PT4M'), 240);
    });
    test('parses days', () {
      expect(parseIsoDurationSeconds('P1DT1H'), 90000);
    });
    test('returns 0 for null or empty', () {
      expect(parseIsoDurationSeconds(null), 0);
      expect(parseIsoDurationSeconds(''), 0);
    });
    test('returns 0 for malformed', () {
      expect(parseIsoDurationSeconds('banana'), 0);
    });
  });

  group('formatDuration', () {
    test('formats under an hour as m:ss', () {
      expect(formatDuration(90), '1:30');
      expect(formatDuration(5), '0:05');
    });
    test('formats over an hour as h:mm:ss', () {
      expect(formatDuration(3723), '1:02:03');
    });
    test('clamps negatives to 0:00', () {
      expect(formatDuration(-10), '0:00');
    });
  });
}
