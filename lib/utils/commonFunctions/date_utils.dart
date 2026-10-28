import 'package:intl/intl.dart';

/// Date helpers. All "today" checks use the device's local date.
class AppDateUtils {
  const AppDateUtils._();

  /// Current local time as ISO-8601 with the UTC offset,
  /// e.g. `2026-10-26T10:30:00+05:30`.
  static String nowIso([DateTime? now]) {
    final time = now ?? DateTime.now();
    final offset = time.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final base = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(time);
    return '$base$sign$hours:$minutes';
  }

  /// Parses an ISO string and converts it to device local time.
  static DateTime? parseLocal(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static bool isSameLocalDay(String? value, DateTime today) {
    final date = parseLocal(value);
    if (date == null) return false;
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// e.g. `26 Oct 2026, 10:30 AM`, or `-` when empty.
  static String formatDisplay(String? value) {
    final date = parseLocal(value);
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}
