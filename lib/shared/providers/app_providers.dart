import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/sms_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/bank_sms_message.dart';
import '../../features/sms/sms_service.dart';

// ─── Repository Providers ─────────────────────────────────────────────────────
final transactionRepoProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final categoryRepoProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final settingsRepoProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final backupRepoProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(
    ref.watch(transactionRepoProvider),
    ref.watch(categoryRepoProvider),
    ref.watch(settingsRepoProvider),
  );
});

// ─── Settings Provider ────────────────────────────────────────────────────────
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(_repo.settings);

  Future<void> update(void Function(AppSettings) updater) async {
    try {
      await _repo.updateField(updater);
      // Clone via JSON to get a new object instance so StateNotifier detects the change
      state = AppSettings.fromJson(_repo.settings.toJson());
    } catch (e, stack) {
      AppLogger.e('SettingsNotifier', 'Failed to update settings', e, stack);
      rethrow;
    }
  }

  Future<void> setThemeMode(int mode) async {
    await update((s) => s.themeMode = mode);
  }

  Future<void> setCurrency(String code, String symbol) async {
    await update((s) {
      s.currency = code;
      s.currencySymbol = symbol;
    });
  }

  Future<void> setUserName(String name) async {
    await update((s) => s.userName = name);
  }

  Future<void> setMonthlyBudget(double? budget) async {
    await update((s) => s.monthlyBudget = budget);
  }

  Future<void> completeOnboarding() async {
    await update((s) => s.onboardingComplete = true);
  }

  Future<void> setNotificationSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await update((s) {
      s.notificationEnabled = enabled;
      s.notificationHour = hour;
      s.notificationMinute = minute;
    });
  }

  Future<void> setSmsReaderEnabled(bool enabled) async {
    await update((s) => s.smsReaderEnabled = enabled);
  }

  Future<void> addSenderIds(List<String> ids) async {
    await update((s) {
      final combined = {...s.knownSenderIds, ...ids}.toList();
      s.knownSenderIds = combined;
    });
  }

  Future<void> removeSenderId(String id) async {
    await update((s) => s.knownSenderIds.remove(id));
  }

  Future<void> setAutoBackup({
    required bool enabled,
    required int hour,
    required int minute,
    required int retentionDays,
  }) async {
    await update((s) {
      s.autoBackupEnabled = enabled;
      s.autoBackupHour = hour;
      s.autoBackupMinute = minute;
      s.backupRetentionDays = retentionDays;
    });
  }

  Future<void> setAppLock({required bool enabled, required String type}) async {
    await update((s) {
      s.appLockEnabled = enabled;
      s.appLockType = type;
    });
  }

  Future<void> setAvatarPath(String? path) async {
    await update((s) => s.avatarPath = path);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepoProvider));
});

// ─── Transaction Providers ────────────────────────────────────────────────────
class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final TransactionRepository _repo;

  TransactionNotifier(this._repo) : super(_repo.getAll());

  void refresh() {
    state = _repo.getAll();
  }

  Future<void> add(TransactionModel tx) async {
    try {
      AppLogger.i('TransactionNotifier', 'Adding transaction id=${tx.id}');
      await _repo.add(tx);
      refresh();
      AppLogger.i('TransactionNotifier', 'Transaction added, total=${state.length}');
    } catch (e, stack) {
      AppLogger.e('TransactionNotifier', 'Failed to add transaction id=${tx.id}', e, stack);
      rethrow;
    }
  }

  Future<void> update(TransactionModel tx) async {
    try {
      AppLogger.i('TransactionNotifier', 'Updating transaction id=${tx.id}');
      await _repo.update(tx);
      refresh();
    } catch (e, stack) {
      AppLogger.e('TransactionNotifier', 'Failed to update transaction id=${tx.id}', e, stack);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      AppLogger.i('TransactionNotifier', 'Deleting transaction id=$id');
      await _repo.delete(id);
      refresh();
    } catch (e, stack) {
      AppLogger.e('TransactionNotifier', 'Failed to delete transaction id=$id', e, stack);
      rethrow;
    }
  }

  List<TransactionModel> get thisMonth => _repo.getThisMonth();
  List<TransactionModel> get today => _repo.getToday();
  List<TransactionModel> get last7Days => _repo.getLast7Days();

  double get totalIncome => _repo.getTotalIncome();
  double get totalExpense => _repo.getTotalExpense();

  double get thisMonthIncome {
    final now = DateTime.now();
    return _repo.getTotalIncome(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 0),
    );
  }

  double get thisMonthExpense {
    final now = DateTime.now();
    return _repo.getTotalExpense(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 0),
    );
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
  return TransactionNotifier(ref.watch(transactionRepoProvider));
});

// ─── Category Providers ───────────────────────────────────────────────────────
class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  final CategoryRepository _repo;

  CategoryNotifier(this._repo) : super(_repo.getAll());

  void refresh() {
    state = _repo.getAll();
  }

  Future<void> add(CategoryModel cat) async {
    await _repo.add(cat);
    refresh();
  }

  Future<void> update(CategoryModel cat) async {
    await _repo.update(cat);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
  }

  Future<void> reorder(List<String> orderedIds) async {
    await _repo.reorder(orderedIds);
    refresh();
  }

  CategoryModel? getById(String id) => _repo.getById(id);

  List<CategoryModel> forType(CategoryType type) => _repo.getByType(type);
}

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<CategoryModel>>((ref) {
  return CategoryNotifier(ref.watch(categoryRepoProvider));
});

// ─── Selected Period Provider (for analytics) ──────────────────────────────
enum AnalyticsPeriod { week, month, year }

final analyticsPeriodProvider = StateProvider<AnalyticsPeriod>(
  (ref) => AnalyticsPeriod.month,
);

// ─── SMS Providers ────────────────────────────────────────────────────────────
final smsRepoProvider = Provider<SmsRepository>((ref) => SmsRepository());

final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService(ref.watch(smsRepoProvider));
});

class SmsNotifier extends StateNotifier<List<BankSmsMessage>> {
  final SmsRepository _repo;

  SmsNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  List<BankSmsMessage> get pending => _repo.getPending();

  Future<void> updateStatus(String id, SmsStatus status) async {
    await _repo.updateStatus(id, status);
    refresh();
  }
}

final smsProvider =
    StateNotifierProvider<SmsNotifier, List<BankSmsMessage>>((ref) {
  return SmsNotifier(ref.watch(smsRepoProvider));
});

// ─── Search / Filter ──────────────────────────────────────────────────────────
final transactionSearchProvider = StateProvider<String>((ref) => '');
final transactionTypeFilterProvider =
    StateProvider<TransactionType?>((ref) => null);

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final all = ref.watch(transactionProvider);
  final search = ref.watch(transactionSearchProvider).toLowerCase();
  final typeFilter = ref.watch(transactionTypeFilterProvider);

  return all.where((t) {
    final matchesSearch = search.isEmpty ||
        t.note.toLowerCase().contains(search) ||
        t.tags.any((tag) => tag.toLowerCase().contains(search));
    final matchesType = typeFilter == null || t.type == typeFilter;
    return matchesSearch && matchesType;
  }).toList();
});
