import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/utils/formatters.dart';

void main() {
  group('AppFormatters.formatAmountCompact', () {
    test('uses K, L and Cr thresholds', () {
      expect(AppFormatters.formatAmountCompact(950, '₹'), '₹950');
      expect(AppFormatters.formatAmountCompact(1500, '₹'), '₹1.5K');
      expect(AppFormatters.formatAmountCompact(250000, '₹'), '₹2.5L');
      expect(AppFormatters.formatAmountCompact(30000000, '₹'), '₹3.0Cr');
    });

    test('drops the sign', () {
      expect(AppFormatters.formatAmountCompact(-1500, r'$'), r'$1.5K');
    });
  });

  group('AppFormatters.formatDate', () {
    test('labels today and yesterday', () {
      final now = DateTime.now();
      expect(AppFormatters.formatDate(now), 'Today');
      expect(
        AppFormatters.formatDate(now.subtract(const Duration(days: 1))),
        'Yesterday',
      );
    });

    test('formats older dates as dd MMM yyyy', () {
      expect(AppFormatters.formatDate(DateTime(2024, 2, 9)), '09 Feb 2024');
    });
  });

  group('AppFormatters.formatFileSize', () {
    test('picks the right unit', () {
      expect(AppFormatters.formatFileSize(512), '512B');
      expect(AppFormatters.formatFileSize(2048), '2.0KB');
      expect(AppFormatters.formatFileSize(3 * 1024 * 1024), '3.0MB');
    });
  });

  test('backupFileName has the expected shape', () {
    expect(
      AppFormatters.backupFileName(),
      matches(RegExp(r'^backup_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}\.json$')),
    );
  });
}
