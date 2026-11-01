import 'package:firebase_core/firebase_core.dart';
import '../../core/utils/app_logger.dart';

/// Initialises Firebase once at startup.
///
/// Shared tracking is optional: when `android/app/google-services.json` is
/// absent the Gradle plugin is skipped, `Firebase.initializeApp` throws, and
/// the app simply runs in its normal offline-only mode with the feature
/// hidden behind an explanatory screen.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool _available = false;
  static String? _error;

  /// True when Firebase initialised and shared tracking can be offered.
  static bool get available => _available;

  /// Why initialisation failed, for the settings screen.
  static String? get error => _error;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _available = true;
      AppLogger.i('FirebaseBootstrap', 'Firebase ready');
    } catch (e) {
      _available = false;
      _error = e.toString();
      AppLogger.w('FirebaseBootstrap',
          'Firebase not configured; shared tracking disabled ($e)');
    }
  }
}
