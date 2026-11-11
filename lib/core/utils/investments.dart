import 'dart:math' as math;

import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

/// How savings and investment accounts are valued.
///
/// An investment account's ledger balance (opening balance plus transfers in,
/// minus transfers out) is what has been *invested*. Its *value* is worked out
/// per type:
///
/// * Fixed deposit: the invested amount compounded quarterly at
///   [AccountModel.interestRate] from [AccountModel.startDate] until today or
///   the maturity date, whichever comes first. This matches how most Indian
///   banks pay a cumulative FD.
/// * Mutual fund / stocks: the last value the user typed in, plus anything
///   invested since that update at face value.
/// * Chit: what has been paid in so far. After the payout is taken (moved out
///   as a transfer) the balance goes negative: the instalments still owed.
///
/// Gains are never posted as income, so monthly income and spending stay as
/// they are.
double investmentValue(AccountModel a, double invested, DateTime now) {
  switch (a.type) {
    case AccountType.fixedDeposit:
      final rate = a.interestRate;
      final start = a.startDate;
      if (rate == null || rate <= 0 || start == null || invested <= 0) {
        return invested;
      }
      final maturity = a.maturityDate;
      final end = maturity != null && maturity.isBefore(now) ? maturity : now;
      return _compoundQuarterly(invested, rate, _years(start, end));
    case AccountType.mutualFund || AccountType.stocks:
      final value = a.marketValue;
      if (value == null) return invested;
      return value + (invested - (a.valuedInvested ?? invested));
    default:
      return invested;
  }
}

/// What a fixed deposit pays out on its maturity date, or null when the
/// terms are incomplete.
double? fdMaturityAmount(AccountModel a, double invested) {
  final rate = a.interestRate;
  final start = a.startDate;
  final maturity = a.maturityDate;
  if (rate == null || rate <= 0 || start == null || maturity == null) {
    return null;
  }
  if (!maturity.isAfter(start) || invested <= 0) return null;
  return _compoundQuarterly(invested, rate, _years(start, maturity));
}

/// Where a chit stands today: month number (1-based, capped at the length),
/// and the instalment per month when the chit amount and length are known.
({int month, int months, double? instalment})? chitProgress(
    AccountModel a, DateTime now) {
  final months = a.chitMonths;
  final start = a.startDate;
  if (months == null || months <= 0 || start == null) return null;
  final elapsed = (now.year - start.year) * 12 + now.month - start.month;
  final month = (elapsed + 1).clamp(0, months);
  final amount = a.chitAmount;
  return (
    month: month,
    months: months,
    instalment: amount != null && amount > 0 ? amount / months : null,
  );
}

double _compoundQuarterly(double principal, double ratePercent, double years) {
  if (years <= 0) return principal;
  return principal * math.pow(1 + ratePercent / 400, 4 * years);
}

double _years(DateTime from, DateTime to) => to.difference(from).inDays / 365.0;

/// Money split for the dashboard: what you can spend, what is put away,
/// what is owed on loans, and all of it together.
class PortfolioSummary {
  /// Cash, bank, wallet, card and other everyday accounts.
  final double available;

  /// Ledger total of every investment account (what went in).
  final double invested;

  /// What those investments are worth today.
  final double investedValue;

  /// Sum of loan balances: zero or negative (minus what is still owed).
  final double loans;

  final bool hasInvestments;
  final bool hasLoans;

  const PortfolioSummary({
    required this.available,
    required this.invested,
    required this.investedValue,
    required this.hasInvestments,
    this.loans = 0,
    this.hasLoans = false,
  });

  double get gain => investedValue - invested;
  double get netWorth => available + investedValue + loans;

  /// Anything beyond everyday accounts, so the dashboard shows the breakdown.
  bool get hasBreakdown => hasInvestments || hasLoans;

  /// Gain as a fraction of what went in, or null when nothing is invested.
  double? get gainRatio => invested > 0 ? gain / invested : null;
}

PortfolioSummary summarisePortfolio(
  Iterable<AccountModel> accounts,
  Map<String, double> balances,
  DateTime now,
) {
  var available = 0.0, invested = 0.0, value = 0.0, loans = 0.0;
  var any = false, anyLoan = false;
  for (final a in accounts) {
    final bal = balances[a.id] ?? a.openingBalance;
    if (a.type.isLoan) {
      anyLoan = true;
      loans += bal;
    } else if (a.type.isInvestment) {
      any = true;
      invested += bal;
      value += investmentValue(a, bal, now);
    } else {
      available += bal;
    }
  }
  return PortfolioSummary(
    available: available,
    invested: invested,
    investedValue: value,
    hasInvestments: any,
    loans: loans,
    hasLoans: anyLoan,
  );
}

/// Net amount moved into savings between [from] and [to] (inclusive):
/// transfers from everyday accounts into investments, chits and loans
/// (EMI principal) count up, money taken back out counts down. Moves
/// between two savings accounts, and loan interest (an expense), don't
/// count. Transfers without an account belong to [defaultAccountId].
double savedBetween(
  Iterable<AccountModel> accounts,
  Iterable<TransactionModel> transactions, {
  required DateTime from,
  required DateTime to,
  required String? defaultAccountId,
}) {
  final saving = {
    for (final a in accounts)
      if (a.type.isInvestment || a.type.isLoan) a.id,
  };
  var saved = 0.0;
  for (final t in transactions) {
    if (t.type != TransactionType.transfer) continue;
    if (t.date.isBefore(from) || t.date.isAfter(to)) continue;
    final src = t.accountId ?? defaultAccountId;
    final dst = t.toAccountId;
    if (src == null || dst == null || src == dst) continue;
    final into = saving.contains(dst), outOf = saving.contains(src);
    if (into && !outOf) saved += t.amount;
    if (outOf && !into) saved -= t.amount;
  }
  return saved;
}
