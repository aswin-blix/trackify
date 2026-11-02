import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
      await _configureLocalTimezone();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          AppLogger.i(
              'NotificationService', 'Notification tapped: ${details.payload}');
        },
      );

      _initialized = true;
      AppLogger.i('NotificationService', 'Initialized');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to initialize', e, stack);
    }
  }

  /// Resolves the device's IANA timezone (e.g. "Asia/Kolkata") so scheduled
  /// times survive DST changes and half-hour offsets. Falls back to a fixed
  /// UTC-offset zone, then to UTC.
  Future<void> _configureLocalTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      AppLogger.i('NotificationService', 'Timezone: ${info.identifier}');
      return;
    } catch (e) {
      AppLogger.w('NotificationService',
          'flutter_timezone failed ($e); falling back to UTC offset');
    }

    try {
      final offset = DateTime.now().timeZoneOffset;
      if (offset.inMinutes == 330) {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } else if (offset.inMinutes % 60 == 0) {
        // Etc/GMT names use an inverted sign convention (Etc/GMT-5 = UTC+5).
        final sign = offset.isNegative ? '+' : '-';
        final hours = offset.inHours.abs();
        tz.setLocalLocation(tz.getLocation('Etc/GMT$sign$hours'));
      }
      // Any other offset: tz.local stays UTC.
    } catch (_) {
      // tz.local stays UTC.
    }
  }

  // ── Request POST_NOTIFICATIONS permission (Android 13+) ────────────────────
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();

      // Request iOS specific permissions explicitly
      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      if (status.isGranted) {
        // Request Alarms & Reminders permission on Android 14+
        final alarmStatus = await Permission.scheduleExactAlarm.status;
        if (!alarmStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }
      }
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

  static const _reminderTitle = '💰 Time to log your expenses!';
  static const _reminderBody =
      'Keep your finances on track — it only takes a minute.';

  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'trackify_daily_reminder',
      'Daily Reminder',
      channelDescription: 'Reminds you to log your daily expenses',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ── Schedule daily reminder ─────────────────────────────────────────────────
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await init();

    // Cancel existing before rescheduling
    await _plugin.cancel(id: kDailyReminderNotifId);

    // Request permission if not granted
    final granted = await hasPermission();
    if (!granted) {
      final result = await requestPermission();
      if (!result) {
        AppLogger.w('NotificationService',
            'Notification permission denied — reminder not scheduled');
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

    try {
      await _plugin.zonedSchedule(
        id: kDailyReminderNotifId,
        title: _reminderTitle,
        body: _reminderBody,
        scheduledDate: scheduled,
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      );

      AppLogger.i(
        'NotificationService',
        'Daily reminder scheduled at $hour:${minute.toString().padLeft(2, '0')} (next: $scheduled)',
      );
    } catch (e) {
      AppLogger.w('NotificationService',
          'Exact alarm failed (likely blocked by Android 14). Falling back to inexact alarm.');

      try {
        await _plugin.zonedSchedule(
          id: kDailyReminderNotifId,
          title: _reminderTitle,
          body: _reminderBody,
          scheduledDate: scheduled,
          notificationDetails: _reminderDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        AppLogger.i('NotificationService',
            'Fallback inexact alarm scheduled successfully.');
      } catch (fallbackErr) {
        AppLogger.e(
            'NotificationService', 'Even fallback alarm failed', fallbackErr);
      }
    }
  }

  // ── Loan due-date reminders ─────────────────────────────────────────────────
  static const _debtDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'trackify_debt_due',
      'Loan reminders',
      channelDescription: 'Reminds you when lent or borrowed money is due',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  /// Replaces every scheduled loan reminder with [reminders]. Called with
  /// the current open loans, so settled ones are cancelled. Never asks for
  /// permission; if notifications are off it quietly does nothing.
  Future<void> syncDebtReminders(
    List<({int id, String title, String body, DateTime at})> reminders,
  ) async {
    try {
      if (!_initialized) await init();
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id >= kDebtNotifIdBase && p.id < kDebtNotifIdBase + 100000) {
          await _plugin.cancel(id: p.id);
        }
      }
      if (!await hasPermission()) return;
      final now = DateTime.now();
      for (final r in reminders) {
        if (!r.at.isAfter(now)) continue;
        final when = tz.TZDateTime.from(r.at, tz.local);
        try {
          await _plugin.zonedSchedule(
            id: r.id,
            title: r.title,
            body: r.body,
            scheduledDate: when,
            notificationDetails: _debtDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (e, stack) {
          AppLogger.e('NotificationService', 'Loan reminder failed', e, stack);
        }
      }
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Loan reminder sync failed', e, stack);
    }
  }

  // ── Cancel daily reminder ───────────────────────────────────────────────────
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(id: kDailyReminderNotifId);
      AppLogger.i('NotificationService', 'Daily reminder cancelled');
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to cancel reminder', e, stack);
    }
  }

  // ── Test Immediate Notification ───────────────────────────────────────────
  Future<void> showTestNotification() async {
    if (!_initialized) await init();
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'trackify_test',
          'Test Alerts',
          channelDescription: 'Testing channel for immediate verification',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      await _plugin.show(
        id: kTestNotifId,
        title: '🚀 Immediate Test Alert',
        body:
            'If you can see this, your phone is allowing Trackify notifications natively!',
        notificationDetails: details,
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
      AppLogger.e('NotificationService', 'Failed to cancel all notifications',
          e, stack);
    }
  }
}
