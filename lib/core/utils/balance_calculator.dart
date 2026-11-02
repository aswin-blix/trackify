import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

/// Current balance of every account: opening balance plus all income into
/// it, minus all expenses from it, plus transfers in, minus transfers out.
///
/// Transactions with no account belong to [defaultAccountId]. A transfer
/// only moves money when both ends are known; an old transfer without a
/// destination is ignored so money does not vanish.
Map<String, double> computeAccountBalances(
  Iterable<AccountModel> accounts,
  Iterable<TransactionModel> transactions, {
  required String? defaultAccountId,
}) {
  final result = <String, double>{
    for (final a in accounts) a.id: a.openingBalance,
  };

  String? resolve(String? id) => id ?? defaultAccountId;

  for (final t in transactions) {
    switch (t.type) {
      // Lending and repaying move money out; borrowing and being paid back
      // move it in. None of them are income or expense.
      case TransactionType.income ||
            TransactionType.borrow ||
            TransactionType.collect:
        final acc = resolve(t.accountId);
        if (acc != null && result.containsKey(acc)) {
          result[acc] = result[acc]! + t.amount;
        }
      case TransactionType.expense ||
            TransactionType.lend ||
            TransactionType.repay:
        final acc = resolve(t.accountId);
        if (acc != null && result.containsKey(acc)) {
          result[acc] = result[acc]! - t.amount;
        }
      case TransactionType.transfer:
        final from = resolve(t.accountId);
        final to = t.toAccountId;
        if (from == null || to == null || from == to) break;
        if (result.containsKey(from)) result[from] = result[from]! - t.amount;
        if (result.containsKey(to)) result[to] = result[to]! + t.amount;
    }
  }
  return result;
}

/// Sum of every account balance. Credit cards are liabilities, so their
/// (normally negative) balance is included as-is; a positive card balance
/// means an overpayment.
double totalBalance(Map<String, double> balances) =>
    balances.values.fold(0.0, (s, v) => s + v);
