import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/services/backup_scheduler.dart';

void main() {
  group('delayUntilNext', () {
    test('targets later today when the time has not passed', () {
      final now = DateTime(2026, 11, 1, 20, 0);
      expect(delayUntilNext(23, 0, now), const Duration(hours: 3));
    });

    test('rolls to tomorrow when the time has passed', () {
      final now = DateTime(2026, 11, 1, 23, 30);
      expect(
          delayUntilNext(23, 0, now), const Duration(hours: 23, minutes: 30));
    });

    test('rolls to tomorrow when the time is exactly now', () {
      final now = DateTime(2026, 11, 1, 23, 0);
      expect(delayUntilNext(23, 0, now), const Duration(hours: 24));
    });

    test('handles month boundaries', () {
      final now = DateTime(2026, 11, 30, 23, 59);
      final d = delayUntilNext(0, 5, now);
      expect(now.add(d), DateTime(2026, 12, 1, 0, 5));
    });
  });
}
