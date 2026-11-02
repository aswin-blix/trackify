import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/debt_ledger.dart';
import '../../shared/providers/app_providers.dart';
import '../household/household_service.dart';

/// Owner key for "me": the signed-in uid when sharing, otherwise ''.
final myDebtOwnerProvider =
    Provider<String>((ref) => ref.watch(currentUidProvider) ?? '');

/// Every person balance, for every household member. Entries without an
/// `addedBy` were made on this phone before sharing, so they are mine.
final allDebtBalancesProvider = Provider<List<PersonBalance>>((ref) {
  final txs = ref.watch(transactionProvider);
  final me = ref.watch(myDebtOwnerProvider);
  return DebtLedger.balances(txs, ownerOf: (t) => t.addedBy ?? me);
});

/// Whose loans the Lent & Borrowed screen shows: null = everyone.
final debtOwnerFilterProvider = StateProvider<String?>((ref) => null);

final myDebtBalancesProvider = Provider<List<PersonBalance>>((ref) {
  final me = ref.watch(myDebtOwnerProvider);
  return ref
      .watch(allDebtBalancesProvider)
      .where((p) => p.owner == me)
      .toList();
});

/// Names I've used before, most recent first, for autocomplete.
final knownDebtPeopleProvider = Provider<List<String>>((ref) {
  final list = [...ref.watch(myDebtBalancesProvider)]
    ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
  return list.map((p) => p.name).toList();
});

/// Schedules a 10:00 reminder on the due date of each of my open loans and
/// cancels the rest. Safe to call often.
Future<void> syncDebtReminders(Ref ref) async {
  final symbol = ref.read(settingsProvider).currencySymbol;
  final reminders = <({int id, String title, String body, DateTime at})>[];
  for (final p in ref.read(myDebtBalancesProvider)) {
    final due = p.dueDate;
    if (p.isSettled || due == null) continue;
    final amount = '$symbol${p.net.abs().toStringAsFixed(0)}';
    reminders.add((
      id: kDebtNotifIdBase +
          (DebtLedger.personKey(p.name).hashCode & 0x7fffffff) % 100000,
      title: p.theyOwe ? 'Payment due from ${p.name}' : 'Pay back ${p.name}',
      body: p.theyOwe
          ? '${p.name} owes you $amount, due today.'
          : 'You owe ${p.name} $amount, due today.',
      at: DateTime(due.year, due.month, due.day, 10),
    ));
  }
  await NotificationService.instance.syncDebtReminders(reminders);
}

/// Callable from widgets (WidgetRef) as well as providers.
final debtReminderSyncProvider = Provider<Future<void> Function()>((ref) {
  return () => syncDebtReminders(ref);
});
