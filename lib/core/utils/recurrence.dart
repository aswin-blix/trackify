/// How often a recurring transaction repeats. Stored by index in Hive, so
/// only append new values.
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

extension RecurrenceFrequencyLabel on RecurrenceFrequency {
  String get label => switch (this) {
        RecurrenceFrequency.daily => 'Daily',
        RecurrenceFrequency.weekly => 'Weekly',
        RecurrenceFrequency.monthly => 'Monthly',
        RecurrenceFrequency.yearly => 'Yearly',
      };

  /// "Every 2 weeks", "Monthly".
  String describe(int interval) {
    if (interval <= 1) return label;
    final unit = switch (this) {
      RecurrenceFrequency.daily => 'days',
      RecurrenceFrequency.weekly => 'weeks',
      RecurrenceFrequency.monthly => 'months',
      RecurrenceFrequency.yearly => 'years',
    };
    return 'Every $interval $unit';
  }
}

class Recurrence {
  const Recurrence._();

  /// The [index]th occurrence (0 = [start]) of a schedule. Each occurrence
  /// is computed from [start], not from the previous one, so a rule set on
  /// the 31st lands on the last day of short months and returns to the 31st
  /// afterwards. Calendar arithmetic keeps the wall-clock time across DST.
  static DateTime occurrence(
    DateTime start,
    RecurrenceFrequency frequency,
    int index, {
    int interval = 1,
  }) {
    final step = index * (interval < 1 ? 1 : interval);
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return _at(start, start.year, start.month, start.day + step);
      case RecurrenceFrequency.weekly:
        return _at(start, start.year, start.month, start.day + 7 * step);
      case RecurrenceFrequency.monthly:
        return _addMonths(start, step);
      case RecurrenceFrequency.yearly:
        return _addMonths(start, 12 * step);
    }
  }

  static DateTime _addMonths(DateTime start, int months) {
    final total = start.month - 1 + months;
    final year = start.year + (total ~/ 12);
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = start.day > lastDay ? lastDay : start.day;
    return _at(start, year, month, day);
  }

  static DateTime _at(DateTime t, int y, int m, int d) =>
      DateTime(y, m, d, t.hour, t.minute, t.second);

  /// Occurrence indexes from [fromIndex] that are due at [now] and not past
  /// [end]. Capped at [max] so a rule left untouched for years can't flood
  /// the ledger in one go.
  static List<int> dueIndexes({
    required DateTime start,
    required RecurrenceFrequency frequency,
    required int interval,
    required int fromIndex,
    required DateTime now,
    DateTime? end,
    int max = 400,
  }) {
    final out = <int>[];
    var i = fromIndex;
    while (out.length < max) {
      final at = occurrence(start, frequency, i, interval: interval);
      if (at.isAfter(now)) break;
      if (end != null && at.isAfter(end)) break;
      out.add(i);
      i++;
    }
    return out;
  }

  /// First occurrence index whose date is after [now]; used when a paused
  /// rule is resumed so missed periods are skipped rather than back-filled.
  static int firstIndexAfter({
    required DateTime start,
    required RecurrenceFrequency frequency,
    required int interval,
    required int fromIndex,
    required DateTime now,
  }) {
    var i = fromIndex;
    // Bounded: ~27 years of daily occurrences.
    for (var guard = 0; guard < 10000; guard++) {
      if (occurrence(start, frequency, i, interval: interval).isAfter(now)) {
        return i;
      }
      i++;
    }
    return i;
  }
}
