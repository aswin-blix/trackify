import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../core/services/backup_scheduler.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/sms_repository.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/models/recurring_model.dart';
import '../../core/utils/recurrence.dart';
import '../../data/models/account_model.dart';
import '../../core/utils/balance_calculator.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/bank_sms_message.dart';
import '../../features/sms/sms_service.dart';
import '../../features/household/household_sync.dart';

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

final accountRepoProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

final recurringRepoProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository();
});

final backupRepoProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(
    ref.watch(transactionRepoProvider),
    ref.watch(categoryRepoProvider),
    ref.watch(settingsRepoProvider),
    ref.watch(accountRepoProvider),
    ref.watch(recurringRepoProvider),
  );
});

// ─── Settings Provider ────────────────────────────────────────────────────────
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repo;
  final HouseholdSync _sync;

  SettingsNotifier(this._repo, this._sync) : super(_repo.settings);

  /// Re-reads settings from storage, e.g. after a restore or reset that
  /// bypassed this notifier.
  void reload() {
    state = AppSettings.fromJson(_repo.settings.toJson());
  }

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
    _sync.pushCurrency(code, symbol);
  }

  Future<void> setUserName(String name) async {
    await update((s) => s.userName = name);
    _sync.pushMemberName(name);
  }

  Future<void> setMonthlyBudget(double? budget) async {
    await update((s) => s.monthlyBudget = budget);
    _sync.pushBudget(budget);
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
    if (enabled) {
      await BackupScheduler.schedule(hour: hour, minute: minute);
    } else {
      await BackupScheduler.cancel();
    }
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
  return SettingsNotifier(
    ref.watch(settingsRepoProvider),
    ref.watch(householdSyncProvider),
  );
});

// ─── Transaction Providers ────────────────────────────────────────────────────
class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final TransactionRepository _repo;
  final HouseholdSync _sync;

  TransactionNotifier(this._repo, this._sync) : super(_repo.getAll());

  void refresh() {
    state = _repo.getAll();
  }

  Future<void> add(TransactionModel tx) async {
    try {
      AppLogger.i('TransactionNotifier', 'Adding transaction id=${tx.id}');
      _sync.stamp(tx);
      await _repo.add(tx);
      refresh();
      _sync.pushTransaction(tx);
      AppLogger.i(
          'TransactionNotifier', 'Transaction added, total=${state.length}');
    } catch (e, stack) {
      AppLogger.e('TransactionNotifier',
          'Failed to add transaction id=${tx.id}', e, stack);
      rethrow;
    }
  }

  Future<void> update(TransactionModel tx) async {
    try {
      AppLogger.i('TransactionNotifier', 'Updating transaction id=${tx.id}');
      _sync.stamp(tx);
      await _repo.update(tx);
      refresh();
      _sync.pushTransaction(tx);
    } catch (e, stack) {
      AppLogger.e('TransactionNotifier',
          'Failed to update transaction id=${tx.id}', e, stack);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      AppLogger.i('TransactionNotifier', 'Deleting transaction id=$id');
      await _repo.delete(id);
      refresh();
      _sync.deleteTransaction(id);
    } catch (e, stack) {
      AppLogger.e('TransactionNotifier', 'Failed to delete transaction id=$id',
          e, stack);
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
      to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  double get thisMonthExpense {
    final now = DateTime.now();
    return _repo.getTotalExpense(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
  return TransactionNotifier(
    ref.watch(transactionRepoProvider),
    ref.watch(householdSyncProvider),
  );
});

// ─── Category Providers ───────────────────────────────────────────────────────
class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  final CategoryRepository _repo;
  final HouseholdSync _sync;

  CategoryNotifier(this._repo, this._sync) : super(_repo.getAll());

  void refresh() {
    state = _repo.getAll();
  }

  Future<void> add(CategoryModel cat) async {
    await _repo.add(cat);
    refresh();
    _sync.pushCategory(cat);
  }

  Future<void> update(CategoryModel cat) async {
    await _repo.update(cat);
    refresh();
    _sync.pushCategory(cat);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
    _sync.deleteCategory(id);
  }

  Future<void> reorder(List<String> orderedIds) async {
    await _repo.reorder(orderedIds);
    refresh();
    _sync.pushCategories(state);
  }

  CategoryModel? getById(String id) => _repo.getById(id);

  List<CategoryModel> forType(CategoryType type) => _repo.getByType(type);
}

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<CategoryModel>>((ref) {
  return CategoryNotifier(
    ref.watch(categoryRepoProvider),
    ref.watch(householdSyncProvider),
  );
});

// ─── Account Providers ────────────────────────────────────────────────────────
class AccountNotifier extends StateNotifier<List<AccountModel>> {
  final Ref _ref;
  final AccountRepository _repo;
  final HouseholdSync _sync;

  AccountNotifier(this._ref, this._repo, this._sync) : super(_repo.getAll());

  void refresh() {
    state = _repo.getAll();
  }

  AccountModel? getById(String? id) => id == null ? null : _repo.getById(id);

  AccountModel? get defaultAccount => _repo.defaultAccount;

  Future<void> add(AccountModel account) async {
    await _repo.add(account);
    refresh();
    _sync.pushAccount(account);
  }

  Future<void> update(AccountModel account) async {
    await _repo.update(account);
    refresh();
    _sync.pushAccount(account);
  }

  Future<void> setDefault(String id) async {
    await _repo.setDefault(id);
    refresh();
    _sync.pushAccounts(state);
  }

  /// Sets opening balances by account id (used by onboarding).
  Future<void> setOpeningBalances(Map<String, double> byId) async {
    for (final entry in byId.entries) {
      final a = _repo.getById(entry.key);
      if (a == null) continue;
      a.openingBalance = entry.value;
      await _repo.update(a);
      _sync.pushAccount(a);
    }
    refresh();
  }

  /// Deletes an account and moves its transactions to the default account.
  Future<void> deleteAndReassign(String id) async {
    final fallback = _repo.getAll().firstWhere(
          (a) => a.isDefault && a.id != id,
          orElse: () => _repo.getAll().firstWhere((a) => a.id != id),
        );
    final txNotifier = _ref.read(transactionProvider.notifier);
    for (final t in _ref.read(transactionProvider)) {
      if (t.accountId != id && t.toAccountId != id) continue;
      await txNotifier.update(t.copyWith(
        accountId: t.accountId == id ? fallback.id : t.accountId,
        toAccountId: t.toAccountId == id ? fallback.id : t.toAccountId,
      ));
    }
    await _repo.delete(id);
    refresh();
    _sync.deleteAccount(id);
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, List<AccountModel>>((ref) {
  return AccountNotifier(
    ref,
    ref.watch(accountRepoProvider),
    ref.watch(householdSyncProvider),
  );
});

/// Live balance per account id, derived from opening balances and every
/// transaction. Recomputed whenever accounts or transactions change.
final accountBalancesProvider = Provider<Map<String, double>>((ref) {
  final accounts = ref.watch(accountProvider);
  final txs = ref.watch(transactionProvider);
  final def = accounts.where((a) => a.isDefault).firstOrNull?.id ??
      accounts.firstOrNull?.id;
  return computeAccountBalances(accounts, txs, defaultAccountId: def);
});

final totalBalanceProvider = Provider<double>(
  (ref) => totalBalance(ref.watch(accountBalancesProvider)),
);

// ─── Recurring Providers ──────────────────────────────────────────────────────
class RecurringNotifier extends StateNotifier<List<RecurringModel>> {
  final Ref _ref;
  final RecurringRepository _repo;
  bool _posting = false;

  RecurringNotifier(this._ref, this._repo) : super(_repo.getAll());

  void refresh() {
    state = _repo.getAll();
  }

  /// Saves a new rule and posts any occurrence already due (a start date of
  /// today or earlier posts the first one straight away).
  Future<int> add(RecurringModel rule) async {
    await _repo.save(rule);
    refresh();
    return postDue();
  }

  Future<void> update(RecurringModel rule) async {
    rule.updatedAt = DateTime.now();
    await _repo.save(rule);
    refresh();
  }

  /// Pausing stops posting. Resuming skips the periods missed while paused
  /// instead of back-filling them.
  Future<void> setActive(String id, bool active) async {
    final rule = _repo.getById(id);
    if (rule == null || rule.active == active) return;
    if (active) {
      rule.postedCount = Recurrence.firstIndexAfter(
        start: rule.startDate,
        frequency: rule.frequency,
        interval: rule.interval,
        fromIndex: rule.postedCount,
        now: DateTime.now(),
      );
    }
    rule.active = active;
    await update(rule);
  }

  /// Deletes the rule. Transactions it already posted are kept.
  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
  }

  /// Posts every due occurrence of every active rule through the normal
  /// transaction path (so they sync to a shared household like any entry).
  /// Returns how many transactions were added.
  Future<int> postDue({DateTime? now}) async {
    if (_posting) return 0;
    _posting = true;
    var added = 0;
    try {
      final at = now ?? DateTime.now();
      final txRepo = _ref.read(transactionRepoProvider);
      final txNotifier = _ref.read(transactionProvider.notifier);
      for (final rule in _repo.getAll()) {
        if (!rule.active) continue;
        final due = Recurrence.dueIndexes(
          start: rule.startDate,
          frequency: rule.frequency,
          interval: rule.interval,
          fromIndex: rule.postedCount,
          now: at,
          end: rule.endDate,
        );
        if (due.isEmpty) continue;
        for (final i in due) {
          final tx = rule.buildTransaction(i, now: at);
          if (txRepo.getById(tx.id) == null) {
            await txNotifier.add(tx);
            added++;
          }
          rule.postedCount = i + 1;
        }
        await _repo.save(rule);
      }
    } catch (e, stack) {
      AppLogger.e(
          'RecurringNotifier', 'Posting due transactions failed', e, stack);
    } finally {
      _posting = false;
      refresh();
    }
    if (added > 0) {
      AppLogger.i('RecurringNotifier', 'Posted $added recurring transactions');
    }
    return added;
  }
}

final recurringProvider =
    StateNotifierProvider<RecurringNotifier, List<RecurringModel>>((ref) {
  return RecurringNotifier(ref, ref.watch(recurringRepoProvider));
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
        t.tags.any((tag) => tag.toLowerCase().contains(search)) ||
        (t.counterparty?.toLowerCase().contains(search) ?? false);
    final matchesType = typeFilter == null ||
        t.type == typeFilter ||
        (typeFilter == TransactionType.lend && t.type.isDebt);
    return matchesSearch && matchesType;
  }).toList();
});
