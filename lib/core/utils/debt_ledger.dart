import '../../data/models/transaction_model.dart';

/// Net position with one person, from one owner's point of view.
///
/// [net] > 0: the person owes the owner. [net] < 0: the owner owes them.
class PersonBalance {
  /// Household member uid who recorded these entries; '' when sharing is
  /// off (everything on this phone is the user's).
  final String owner;

  /// Display name as first typed.
  final String name;
  final double net;

  /// Entries for this person, oldest first.
  final List<TransactionModel> entries;

  /// Earliest due date among loans still outstanding, if any.
  final DateTime? dueDate;

  const PersonBalance({
    required this.owner,
    required this.name,
    required this.net,
    required this.entries,
    this.dueDate,
  });

  bool get isSettled => net.abs() < 0.005;
  bool get theyOwe => net > 0.005;
  bool get youOwe => net < -0.005;

  bool isOverdue(DateTime now) =>
      !isSettled && dueDate != null && dueDate!.isBefore(now);

  DateTime get lastActivity => entries.last.date;
}

class DebtLedger {
  const DebtLedger._();

  /// Effect of an entry on what the person owes the owner.
  static double effect(TransactionModel t) => switch (t.type) {
        TransactionType.lend => t.amount,
        TransactionType.repay => t.amount,
        TransactionType.borrow => -t.amount,
        TransactionType.collect => -t.amount,
        _ => 0,
      };

  /// Case- and space-insensitive key so "Rahul", "rahul " and "RAHUL" are
  /// one person.
  static String personKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Groups lend/borrow/collect/repay entries by (owner, person) and works
  /// out the running balance. [ownerOf] maps an entry to its owner key.
  static List<PersonBalance> balances(
    Iterable<TransactionModel> transactions, {
    required String Function(TransactionModel) ownerOf,
  }) {
    final groups = <String, List<TransactionModel>>{};
    for (final t in transactions) {
      if (!t.type.isDebt) continue;
      final who = t.counterparty?.trim();
      if (who == null || who.isEmpty) continue;
      final key = '${ownerOf(t)}\u0000${personKey(who)}';
      (groups[key] ??= []).add(t);
    }

    final out = <PersonBalance>[];
    for (final entry in groups.entries) {
      final list = entry.value..sort((a, b) => a.date.compareTo(b.date));
      var net = 0.0;
      // Due dates of loans made since the balance last touched zero.
      var openDues = <DateTime>[];
      for (final t in list) {
        net += effect(t);
        if (net.abs() < 0.005) {
          net = 0;
          openDues = [];
        } else if ((t.type == TransactionType.lend ||
                t.type == TransactionType.borrow) &&
            t.dueDate != null) {
          openDues.add(t.dueDate!);
        }
      }
      openDues.sort();
      out.add(PersonBalance(
        owner: entry.key.split('\u0000').first,
        name: list.first.counterparty!.trim(),
        net: net,
        entries: list,
        dueDate: openDues.isEmpty ? null : openDues.first,
      ));
    }

    // Open balances first (largest first), then settled by recency.
    out.sort((a, b) {
      if (a.isSettled != b.isSettled) return a.isSettled ? 1 : -1;
      if (!a.isSettled) return b.net.abs().compareTo(a.net.abs());
      return b.lastActivity.compareTo(a.lastActivity);
    });
    return out;
  }

  /// Total others owe across [list], and total owed to others.
  static ({double owedToYou, double youOwe}) totals(
      Iterable<PersonBalance> list) {
    var owed = 0.0, owe = 0.0;
    for (final p in list) {
      if (p.theyOwe) owed += p.net;
      if (p.youOwe) owe += -p.net;
    }
    return (owedToYou: owed, youOwe: owe);
  }

  /// Short label for an entry, e.g. "Lent to Rahul".
  static String describe(TransactionModel t) {
    final who = t.counterparty ?? 'someone';
    return switch (t.type) {
      TransactionType.lend => 'Lent to $who',
      TransactionType.borrow => 'Borrowed from $who',
      TransactionType.collect => 'Paid back by $who',
      TransactionType.repay => 'Paid back to $who',
      _ => who,
    };
  }
}
