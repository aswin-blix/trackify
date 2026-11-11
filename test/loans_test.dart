import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/utils/investments.dart';
import 'package:trackify/core/utils/loans.dart';
import 'package:trackify/data/models/account_model.dart';
import 'package:trackify/data/models/category_model.dart';
import 'package:trackify/features/accounts/manage_accounts_screen.dart';

void main() {
  group('splitEmi', () {
    test('interest is a month of the yearly rate on what is owed', () {
      final s = splitEmi(payment: 10000, owed: 500000, annualRatePercent: 9);
      expect(s.interest, 3750);
      expect(s.principal, 6250);
    });

    test('no-cost EMI is all principal', () {
      final s = splitEmi(payment: 5000, owed: 60000, annualRatePercent: 0);
      expect(s.interest, 0);
      expect(s.principal, 5000);
    });

    test('nothing owed means no interest', () {
      final s = splitEmi(payment: 5000, owed: 0, annualRatePercent: 10);
      expect(s.interest, 0);
    });

    test('interest never exceeds the payment', () {
      final s = splitEmi(payment: 100, owed: 500000, annualRatePercent: 12);
      expect(s.interest, 100);
      expect(s.principal, 0);
    });

    test('twelve EMIs clear a 12-month loan, matching the bank schedule', () {
      // ₹1,00,000 at 12% for 12 months: EMI ₹8,884.88.
      var owed = 100000.0;
      var interestPaid = 0.0;
      for (var m = 0; m < 12; m++) {
        final s = splitEmi(payment: 8884.88, owed: owed, annualRatePercent: 12);
        owed -= s.principal;
        interestPaid += s.interest;
      }
      expect(owed.abs(), lessThan(1.0));
      expect(interestPaid, closeTo(6618.55, 1.0));
    });
  });

  group('emisLeft', () {
    test('reducing-balance loan', () {
      expect(emisLeft(owed: 100000, emi: 8884.88, annualRatePercent: 12), 12);
      expect(emisLeft(owed: 500000, emi: 10000, annualRatePercent: 9), 63);
    });

    test('no-cost EMI', () {
      expect(emisLeft(owed: 60000, emi: 5000, annualRatePercent: 0), 12);
      expect(emisLeft(owed: 61000, emi: 5000, annualRatePercent: 0), 13);
    });

    test('EMI below the monthly interest never finishes', () {
      expect(emisLeft(owed: 500000, emi: 3000, annualRatePercent: 9), isNull);
    });

    test('paid off or unknown EMI', () {
      expect(emisLeft(owed: 0, emi: 5000, annualRatePercent: 9), 0);
      expect(emisLeft(owed: 1000, emi: null, annualRatePercent: 9), isNull);
    });
  });

  test('loans lower net worth but not money available to spend', () {
    final bank = AccountModel(id: 'bank', name: 'Bank');
    final car = AccountModel(id: 'car', name: 'Car', type: AccountType.loan);
    final s = summarisePortfolio(
        [bank, car], {'bank': 80000, 'car': -300000}, DateTime(2026, 11, 11));
    expect(s.available, 80000);
    expect(s.loans, -300000);
    expect(s.netWorth, -220000);
    expect(s.hasLoans, isTrue);
    expect(s.hasInvestments, isFalse);
    expect(s.hasBreakdown, isTrue);
  });

  test('loan balance is entered as owed and stored negative', () {
    expect(signedOpening(AccountType.loan, 250000), -250000);
    expect(signedOpening(AccountType.card, 2000), -2000);
    expect(signedOpening(AccountType.bank, 2000), 2000);
  });

  test('loan tile shows rate, EMI and how many are left', () {
    final loan = AccountModel(
      id: 'l',
      name: 'Car loan',
      type: AccountType.loan,
      interestRate: 9,
      emiAmount: 10000,
    );
    final text = investmentDetails(loan, -500000, -500000, '₹',
        now: DateTime(2026, 11, 11))!;
    expect(text, contains('9% a year'));
    expect(text, contains('63 EMIs left'));
    expect(investmentDetails(loan, 0, 0, '₹'), 'Paid off');
  });

  test('Loan Interest is a default expense category with a fixed id', () {
    final cat =
        defaultCategories.firstWhere((c) => c.id == kLoanInterestCategoryId);
    expect(cat.type, CategoryType.expense);
  });
}
