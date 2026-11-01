import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/app_settings.dart';
import 'transaction_repository.dart';
import 'category_repository.dart';
import 'settings_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/formatters.dart';

/// Thrown when a backup file cannot be parsed or fails validation.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

/// Fully parsed, validated contents of a backup file.
class BackupContents {
  final List<CategoryModel> categories;
  final List<TransactionModel> transactions;
  final AppSettings? settings;
  final String? appVersion;

  const BackupContents({
    required this.categories,
    required this.transactions,
    this.settings,
    this.appVersion,
  });
}

class BackupRepository {
  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;
  final SettingsRepository _settingsRepo;

  BackupRepository(this._txRepo, this._catRepo, this._settingsRepo);

  static const String _backupPrefix = 'backup_';
  static const String _preRestorePrefix = 'pre_restore_';

  Future<Directory> get _backupDir async {
    final base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$kBackupFolder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Map<String, dynamic> _snapshot() {
    final transactions = _txRepo.getAll();
    final categories = _catRepo.getAll();
    final settings = _settingsRepo.settings;

    return {
      'meta': {
        'version': kAppVersion,
        'schema': kBackupSchemaVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'transactionCount': transactions.length,
        'categoryCount': categories.length,
      },
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'settings': settings.toJson(),
    };
  }

  Future<String> createBackup() async {
    final dir = await _backupDir;
    final fileName = AppFormatters.backupFileName();
    final file = File('${dir.path}/$fileName');

    await file.writeAsString(jsonEncode(_snapshot()));

    // Update last backup time
    await _settingsRepo.updateField((s) => s.lastBackupAt = DateTime.now());

    // Clean up old backups
    await _pruneOldBackups(_settingsRepo.settings.backupRetentionDays);

    return file.path;
  }

  /// Creates a backup if auto-backup is enabled and the last one is older
  /// than 24 hours. Returns the new file path, or null if nothing was done.
  Future<String?> runAutoBackupIfDue() async {
    final settings = _settingsRepo.settings;
    if (!settings.autoBackupEnabled) return null;
    final last = settings.lastBackupAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(hours: 24)) {
      return null;
    }
    try {
      final path = await createBackup();
      AppLogger.i('BackupRepository', 'Auto backup written to $path');
      return path;
    } catch (e, stack) {
      AppLogger.e('BackupRepository', 'Auto backup failed', e, stack);
      return null;
    }
  }

  /// Parses and validates a backup file without touching stored data.
  Future<BackupContents> parseBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const BackupFormatException('Backup file not found.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FormatException {
      throw const BackupFormatException('File is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException('File is not a Trackify backup.');
    }
    final data = decoded;

    final rawCats = data['categories'];
    final rawTxs = data['transactions'];
    if (rawCats is! List || rawTxs is! List) {
      throw const BackupFormatException(
          'Backup is missing categories or transactions.');
    }

    final categories = <CategoryModel>[];
    for (var i = 0; i < rawCats.length; i++) {
      final c = rawCats[i];
      if (c is! Map<String, dynamic>) {
        throw BackupFormatException('Category #${i + 1} is malformed.');
      }
      try {
        categories.add(CategoryModel.fromJson(c));
      } catch (e) {
        throw BackupFormatException('Category #${i + 1} is malformed: $e');
      }
    }

    final transactions = <TransactionModel>[];
    for (var i = 0; i < rawTxs.length; i++) {
      final t = rawTxs[i];
      if (t is! Map<String, dynamic>) {
        throw BackupFormatException('Transaction #${i + 1} is malformed.');
      }
      try {
        transactions.add(TransactionModel.fromJson(t));
      } catch (e) {
        throw BackupFormatException('Transaction #${i + 1} is malformed: $e');
      }
    }

    AppSettings? settings;
    final rawSettings = data['settings'];
    if (rawSettings is Map<String, dynamic>) {
      try {
        settings = AppSettings.fromJson(rawSettings);
      } catch (e) {
        throw BackupFormatException('Settings block is malformed: $e');
      }
    }

    final meta = data['meta'];
    final version = meta is Map ? meta['version']?.toString() : null;

    return BackupContents(
      categories: categories,
      transactions: transactions,
      settings: settings,
      appVersion: version,
    );
  }

  /// Restores from [filePath]. The file is fully parsed and validated before
  /// any existing data is removed, and a pre-restore snapshot is written so
  /// the previous state can be recovered.
  Future<BackupContents> restoreFromFile(String filePath) async {
    final contents = await parseBackupFile(filePath);

    // Safety net: snapshot current data before overwriting it.
    try {
      final dir = await _backupDir;
      final stamp =
          AppFormatters.backupFileName().substring(_backupPrefix.length);
      final snapshot = File('${dir.path}/$_preRestorePrefix$stamp');
      await snapshot.writeAsString(jsonEncode(_snapshot()));
    } catch (e, stack) {
      AppLogger.e(
          'BackupRepository', 'Failed to write pre-restore snapshot', e, stack);
    }

    await _txRepo.deleteAll();
    await _catRepo.deleteAll();

    for (final c in contents.categories) {
      await _catRepo.add(c);
    }
    for (final t in contents.transactions) {
      await _txRepo.add(t);
    }

    final restoredSettings = contents.settings;
    if (restoredSettings != null) {
      // Never let a restored file turn the onboarding gate back on.
      restoredSettings.onboardingComplete = true;
      // Household membership belongs to this device and account, not to the
      // backup file.
      restoredSettings.householdId = _settingsRepo.settings.householdId;
      await _settingsRepo.save(restoredSettings);
    }

    return contents;
  }

  /// Escapes a single CSV field: wraps it in quotes, doubles embedded quotes,
  /// and neutralises spreadsheet formula injection (=, +, -, @, tab, CR).
  static String csvEscape(String value) {
    var v = value;
    if (v.isNotEmpty && RegExp(r'^[=+\-@\t\r]').hasMatch(v)) {
      v = "'$v";
    }
    return '"${v.replaceAll('"', '""')}"';
  }

  Future<String> exportToCsv() async {
    final dir = await _backupDir;
    final now = DateTime.now();
    final fileName =
        'transactions_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.csv';
    final file = File('${dir.path}/$fileName');

    final transactions = _txRepo.getAll();
    final categories = _catRepo.getAll();
    final catMap = {for (final c in categories) c.id: c.name};

    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Amount,Note,Tags');
    for (final t in transactions) {
      final catName = catMap[t.categoryId] ?? t.categoryId;
      buffer.writeln([
        t.date.toIso8601String(),
        t.type.name,
        csvEscape(catName),
        t.amount.toStringAsFixed(2),
        csvEscape(t.note),
        csvEscape(t.tags.join(';')),
      ].join(','));
    }

    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// All backup files (regular and pre-restore snapshots), newest first.
  Future<List<FileSystemEntity>> listBackups() async {
    final dir = await _backupDir;
    final files = await dir.list().toList();
    final backups =
        files.whereType<File>().where((f) => f.path.endsWith('.json')).toList();
    backups.sort((a, b) => b.path.compareTo(a.path));
    return backups;
  }

  /// Deletes regular backups whose last-modified time is older than
  /// [retentionDays]. Pre-restore snapshots and the newest backup are kept.
  Future<void> _pruneOldBackups(int retentionDays) async {
    if (retentionDays <= 0) return;
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final backups = await listBackups();
    final regular = backups
        .whereType<File>()
        .where((f) => fileName(f.path).startsWith(_backupPrefix))
        .toList();
    // Always keep the most recent one regardless of age.
    for (final f in regular.skip(1)) {
      try {
        final modified = await f.lastModified();
        if (modified.isBefore(cutoff)) await f.delete();
      } catch (e, stack) {
        AppLogger.e('BackupRepository', 'Failed to prune ${f.path}', e, stack);
      }
    }
  }

  Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteAllBackups() async {
    for (final f in await listBackups()) {
      try {
        await f.delete();
      } catch (_) {
        // Best effort; a locked file shouldn't abort the whole wipe.
      }
    }
  }

  static String fileName(String path) => path.split('/').last.split('\\').last;
}
