/// Utilities for parsing and formatting YouTube ISO-8601 durations.
library;

final RegExp _isoDuration = RegExp(
  r'^P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$',
);

/// Parses an ISO-8601 duration string (e.g. `PT1M30S`, `PT45S`, `PT1H2M`) as
/// returned by the YouTube Data API `contentDetails.duration` field into the
/// total number of seconds. Returns 0 for null or unparseable input.
int parseIsoDurationSeconds(String? iso) {
  if (iso == null || iso.isEmpty) return 0;
  final match = _isoDuration.firstMatch(iso);
  if (match == null) return 0;
  final days = int.tryParse(match.group(1) ?? '') ?? 0;
  final hours = int.tryParse(match.group(2) ?? '') ?? 0;
  final minutes = int.tryParse(match.group(3) ?? '') ?? 0;
  final seconds = int.tryParse(match.group(4) ?? '') ?? 0;
  return ((days * 24 + hours) * 60 + minutes) * 60 + seconds;
}

/// Formats a number of seconds as `m:ss` (or `h:mm:ss` for long videos).
String formatDuration(int totalSeconds) {
  if (totalSeconds < 0) totalSeconds = 0;
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) {
    final mm = m.toString().padLeft(2, '0');
    return '$h:$mm:$ss';
  }
  return '$m:$ss';
}
