import 'dart:math' as math;

/// Category every loan's interest is booked under. A fixed id so both phones
/// in a household end up with the same category.
const String kLoanInterestCategoryId = 'loan_interest';

/// Splits one EMI paid into a loan account.
///
/// A loan account's balance is minus what is still owed. Each month the bank
/// charges interest on that amount at [annualRatePercent] / 12; the rest of
/// the EMI repays principal. This is how a reducing-balance loan (home, car,
/// personal, card EMI) amortises, so the owed amount tracks the bank's
/// schedule without Trackify needing the original loan terms.
///
/// A rate of 0 (a no-cost EMI) or nothing owed means the whole payment is
/// principal. Interest is rounded to paise and never exceeds the payment.
({double principal, double interest}) splitEmi({
  required double payment,
  required double owed,
  required double annualRatePercent,
}) {
  if (payment <= 0 || owed <= 0 || annualRatePercent <= 0) {
    return (principal: payment, interest: 0);
  }
  final raw = owed * annualRatePercent / 1200;
  final interest = math.min(payment, (raw * 100).roundToDouble() / 100);
  return (principal: payment - interest, interest: interest);
}

/// How many more EMIs of [emi] clear [owed] at [annualRatePercent], or null
/// when the EMI does not even cover the monthly interest (or is unknown).
int? emisLeft({
  required double owed,
  required double? emi,
  required double annualRatePercent,
}) {
  if (owed <= 0.5) return 0;
  if (emi == null || emi <= 0) return null;
  final i = annualRatePercent / 1200;
  if (i <= 0) return (owed / emi - 1e-9).ceil();
  if (emi <= owed * i) return null;
  final n = -math.log(1 - owed * i / emi) / math.log(1 + i);
  return (n - 1e-9).ceil();
}
