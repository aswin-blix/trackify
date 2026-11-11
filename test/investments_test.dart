import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/utils/investments.dart';
import 'package:trackify/data/models/account_model.dart';
import 'package:trackify/features/accounts/manage_accounts_screen.dart';

void main() {
  final now = DateTime(2026, 11, 11);

  group('fixed deposit', () {
    final fd = AccountModel(
      id: 'fd',
      name: 'SBI FD',
      type: AccountType.fixedDeposit,
      openingBalance: 100000,
      interestRate: 7.0,
      startDate: DateTime(2025, 11, 11),
      maturityDate: DateTime(2027, 11, 11),
    );

    test('compounds quarterly from the start date', () {
      // One year at 7% compounded quarterly: (1 + 0.0175)^4.
      final v = investmentValue(fd, 100000, now);
      expect(v, closeTo(107185.9, 1.0));
    });

    test('stops growing at maturity', () {
      final later = investmentValue(fd, 100000, DateTime(2030, 1, 1));
      final atMaturity = fdMaturityAmount(fd, 100000)!;
      expect(later, closeTo(atMaturity, 0.01));
      expect(atMaturity, closeTo(114888.0, 2.0));
    });

    test('without rate or start date the value is the deposit', () {
      final bare =
          AccountModel(id: 'x', name: 'FD', type: AccountType.fixedDeposit);
      expect(investmentValue(bare, 50000, now), 50000);
      expect(fdMaturityAmount(bare, 50000), isNull);
    });

    test('a start date in the future does not shrink the value', () {
      final future = fd.copyWith()..startDate = DateTime(2027, 1, 1);
      expect(investmentValue(future, 100000, now), 100000);
    });
  });

  group('mutual fund / stocks', () {
    test('uses the typed-in value', () {
      final mf =
          AccountModel(id: 'mf', name: 'SIP', type: AccountType.mutualFund)
              .withMarketValue(145000, 120000, now);
      expect(investmentValue(mf, 120000, now), 145000);
    });

    test('a SIP after the update counts at face value, not as a loss', () {
      final mf =
          AccountModel(id: 'mf', name: 'SIP', type: AccountType.mutualFund)
              .withMarketValue(145000, 120000, now);
      // ₹5,000 SIP transferred in after the value was entered.
      expect(investmentValue(mf, 125000, now), 150000);
    });

    test('no value yet means value equals what was invested', () {
      final s =
          AccountModel(id: 's', name: 'Zerodha', type: AccountType.stocks);
      expect(investmentValue(s, 80000, now), 80000);
    });
  });

  group('chit', () {
    final chit = AccountModel(
      id: 'c',
      name: 'Kuri',
      type: AccountType.chit,
      startDate: DateTime(2026, 4, 5),
      chitAmount: 100000,
      chitMonths: 20,
    );

    test('month count and instalment', () {
      final p = chitProgress(chit, now)!;
      expect(p.month, 8); // Apr..Nov
      expect(p.months, 20);
      expect(p.instalment, 5000);
    });

    test('month is capped at the chit length', () {
      expect(chitProgress(chit, DateTime(2030, 1, 1))!.month, 20);
    });

    test('value is what has been paid in', () {
      expect(investmentValue(chit, 40000, now), 40000);
    });

    test('after the payout the remaining instalments show as owed', () {
      final text = investmentDetails(chit, -55000, -55000, '₹', now: now);
      expect(text, contains('still to pay'));
    });
  });

  group('portfolio summary', () {
    test('splits available from invested and adds up net worth', () {
      final bank = AccountModel(id: 'bank', name: 'Bank', openingBalance: 0);
      final card =
          AccountModel(id: 'card', name: 'Card', type: AccountType.card);
      final mf =
          AccountModel(id: 'mf', name: 'SIP', type: AccountType.mutualFund)
              .withMarketValue(110000, 100000, now);
      final s = summarisePortfolio(
        [bank, card, mf],
        {'bank': 50000, 'card': -8000, 'mf': 100000},
        now,
      );
      expect(s.available, 42000);
      expect(s.invested, 100000);
      expect(s.investedValue, 110000);
      expect(s.gain, 10000);
      expect(s.gainRatio, closeTo(0.10, 1e-9));
      expect(s.netWorth, 152000);
      expect(s.hasInvestments, isTrue);
    });

    test('no investment accounts: everything is available', () {
      final s = summarisePortfolio(
          [AccountModel(id: 'b', name: 'Bank')], {'b': 900}, now);
      expect(s.hasInvestments, isFalse);
      expect(s.available, 900);
      expect(s.netWorth, 900);
      expect(s.gainRatio, isNull);
    });
  });

  test('investment fields survive a JSON round-trip', () {
    final a = AccountModel(
      id: 'fd',
      name: 'FD',
      type: AccountType.fixedDeposit,
      openingBalance: 100000,
      interestRate: 7.1,
      startDate: DateTime(2025, 1, 2),
      maturityDate: DateTime(2027, 1, 2),
      chitAmount: 5,
      chitMonths: 3,
    ).withMarketValue(1, 2, DateTime(2026, 3, 4));
    final back = AccountModel.fromJson(a.toJson());
    expect(back.type, AccountType.fixedDeposit);
    expect(back.interestRate, 7.1);
    expect(back.startDate, DateTime(2025, 1, 2));
    expect(back.maturityDate, DateTime(2027, 1, 2));
    expect(back.marketValue, 1);
    expect(back.valuedInvested, 2);
    expect(back.valueUpdatedAt, DateTime(2026, 3, 4));
    expect(back.chitAmount, 5);
    expect(back.chitMonths, 3);
  });

  test('an unknown account type from a newer app falls back to Other', () {
    final back =
        AccountModel.fromJson({'id': 'z', 'name': 'Z', 'type': 'crypto'});
    expect(back.type, AccountType.other);
  });
}
