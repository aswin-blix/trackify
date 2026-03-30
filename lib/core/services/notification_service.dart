import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialise ──────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      // Resolve the device's local timezone using the UTC offset.
      // Etc/GMT names use inverted sign convention (Etc/GMT-5 = UTC+5).
      try {
        final offset = DateTime.now().timeZoneOffset;
        final sign = offset.isNegative ? '+' : '-';
        final hours = offset.inHours.abs();
        tz.setLocalLocation(tz.getLocation('Etc/GMT$sign$hours'));
      } catch (_) {
        // Falls back to UTC — still correct for whole-hour offset zones.
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          AppLogger.i('NotificationService', 'Notification tapped: ${details.payload}');
        },
      );

      _initialized = true;
      AppLogger.i('NotificationService', 'Initialized');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to initialize', e, stack);
    }
  }

  // ── Request POST_NOTIFICATIONS permission (Android 13+) ────────────────────
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      AppLogger.i('NotificationService', 'Notification permission: $status');
      return status.isGranted;
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Permission request failed', e, stack);
      return false;
    }
  }

  Future<bool> hasPermission() async {
    return Permission.notification.isGranted;
  }

  // ── Schedule daily reminder ─────────────────────────────────────────────────
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await init();

    try {
      // Cancel existing before rescheduling
      await _plugin.cancel(kDailyReminderNotifId);

      // Request permission if not granted
      final granted = await hasPermission();
      if (!granted) {
        final result = await requestPermission();
        if (!result) {
          AppLogger.w('NotificationService', 'Notification permission denied — reminder not scheduled');
          return;
        }
      }

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'trackify_daily_reminder',
        'Daily Reminder',
        channelDescription: 'Reminds you to log your daily expenses',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const details = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        kDailyReminderNotifId,
        '💰 Time to log your expenses!',
        'Keep your finances on track — it only takes a minute.',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      AppLogger.i(
        'NotificationService',
        'Daily reminder scheduled at $hour:${minute.toString().padLeft(2, '0')} (next: $scheduled)',
      );
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to schedule daily reminder', e, stack);
    }
  }

  // ── Cancel daily reminder ───────────────────────────────────────────────────
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(kDailyReminderNotifId);
      AppLogger.i('NotificationService', 'Daily reminder cancelled');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to cancel reminder', e, stack);
    }
  }

  // ── Test Immediate Notification ───────────────────────────────────────────
  Future<void> showTestNotification() async {
    if (!_initialized) await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'trackify_test',
        'Test Alerts',
        channelDescription: 'Testing channel for immediate verification',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        kDailyReminderNotifId + 1,
        '🚀 Immediate Test Alert',
        'If you can see this, your phone is allowing Trackify notifications natively!',
        details,
      );
      AppLogger.i('NotificationService', 'Immediate test notification fired');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to send test notif', e, stack);
    }
  }

  // ── Cancel all ──────────────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      AppLogger.i('NotificationService', 'All notifications cancelled');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to cancel all notifications', e, stack);
    }
  }
}
