import 'package:intl/intl.dart';

class AppFormatters {
  static String formatAmount(double amount, String currencySymbol) {
    final formatter = NumberFormat('#,##,##0.00');
    return '$currencySymbol${formatter.format(amount.abs())}';
  }

  static String formatAmountCompact(double amount, String currencySymbol) {
    if (amount.abs() >= 10000000) {
      return '$currencySymbol${(amount.abs() / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount.abs() >= 100000) {
      return '$currencySymbol${(amount.abs() / 100000).toStringAsFixed(1)}L';
    } else if (amount.abs() >= 1000) {
      return '$currencySymbol${(amount.abs() / 1000).toStringAsFixed(1)}K';
    }
    return '$currencySymbol${amount.abs().toStringAsFixed(0)}';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatMonthShort(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  static String formatDayShort(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  static String formatGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  static String backupFileName() {
    final now = DateTime.now();
    return 'backup_${DateFormat('yyyy-MM-dd_HH-mm').format(now)}.json';
  }
}
