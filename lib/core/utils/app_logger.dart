import 'package:flutter/foundation.dart';

/// Lightweight structured logger.
/// In debug builds: prints all levels.
/// In release builds: only prints warnings and errors.
class AppLogger {
  const AppLogger._();

  static void i(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[INFO]  [$tag] $message');
    }
  }

  static void w(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[WARN]  [$tag] $message');
    }
  }

  static void e(String tag, String message,
      [Object? error, StackTrace? stack]) {
    // Always print errors — even in release (visible in logcat/crash logs)
    debugPrint('[ERROR] [$tag] $message');
    if (error != null) debugPrint('[ERROR] [$tag] $error');
    if (stack != null && kDebugMode) debugPrint('[ERROR] [$tag] $stack');
  }
}
