import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/repositories/account_repository.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../utils/app_logger.dart';
import 'hive_setup.dart';

const _tag = 'BackupScheduler';

/// WorkManager identifiers. The unique name de-duplicates the periodic job;
/// the task name is what the dispatcher switches on.
const String kBackupTaskName = 'trackify.autoBackup';
const String kBackupUniqueName = 'trackify_auto_backup';

/// Time from [now] until the next occurrence of [hour]:[minute].
/// If that moment has already passed today, it is tomorrow's.
Duration delayUntilNext(int hour, int minute, DateTime now) {
  var target = DateTime(now.year, now.month, now.day, hour, minute);
  if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
  return target.difference(now);
}

/// Entry point WorkManager calls in a background isolate, possibly while the
/// app is closed. It must be a top-level function kept by the VM.
///
/// Only reads Hive and writes a backup file. It never writes to a Hive box,
/// because the app may have the same boxes open in its own isolate; the
/// "last backup" time is derived from the newest file instead.
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != kBackupTaskName) return true;
    try {
      await Hive.initFlutter();
      HiveSetup.registerAdapters();
      await HiveSetup.openBackupBoxes();

      final settingsRepo = SettingsRepository();
      if (!settingsRepo.settings.autoBackupEnabled) {
        AppLogger.i(_tag, 'Auto backup disabled; nothing to do');
        return true;
      }
      final repo = BackupRepository(
        TransactionRepository(),
        CategoryRepository(),
        settingsRepo,
        AccountRepository(),
      );
      final path = await repo.createBackup(recordInSettings: false);
      AppLogger.i(_tag, 'Background backup written to $path');
      return true;
    } catch (e, s) {
      AppLogger.e(_tag, 'Background backup failed', e, s);
      // false → WorkManager retries with backoff.
      return false;
    } finally {
      try {
        await Hive.close();
      } catch (_) {}
    }
  });
}

/// Schedules the daily background backup through Android WorkManager.
///
/// WorkManager runs periodic work roughly on schedule: the first run is at
/// the chosen time, later runs drift a little as the OS batches jobs. The
/// on-open check in `BackupRepository.runAutoBackupIfDue` remains as a
/// safety net for days the OS skipped the job.
class BackupScheduler {
  const BackupScheduler._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Workmanager().initialize(backupCallbackDispatcher);
      _initialized = true;
    } catch (e, s) {
      AppLogger.e(_tag, 'WorkManager init failed', e, s);
    }
  }

  /// Registers (or re-registers) the daily job to first run at [hour]:[minute].
  static Future<void> schedule({
    required int hour,
    required int minute,
    bool replace = true,
  }) async {
    if (!_initialized) return;
    final delay = delayUntilNext(hour, minute, DateTime.now());
    try {
      await Workmanager().registerPeriodicTask(
        kBackupUniqueName,
        kBackupTaskName,
        frequency: const Duration(hours: 24),
        initialDelay: delay,
        existingWorkPolicy: replace
            ? ExistingPeriodicWorkPolicy.update
            : ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(requiresStorageNotLow: true),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
      AppLogger.i(_tag,
          'Daily backup scheduled; first run in ${delay.inMinutes} min (${replace ? 'update' : 'keep'})');
    } catch (e, s) {
      AppLogger.e(_tag, 'Scheduling failed', e, s);
    }
  }

  static Future<void> cancel() async {
    if (!_initialized) return;
    try {
      await Workmanager().cancelByUniqueName(kBackupUniqueName);
      AppLogger.i(_tag, 'Daily backup cancelled');
    } catch (e, s) {
      AppLogger.e(_tag, 'Cancel failed', e, s);
    }
  }

  /// Called at startup: keeps an existing job, creates one if missing.
  static Future<void> ensureScheduled({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (!enabled) {
      await cancel();
      return;
    }
    await schedule(hour: hour, minute: minute, replace: false);
  }
}
