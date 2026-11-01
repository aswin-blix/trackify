import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/utils/balance_calculator.dart';
import 'package:trackify/data/models/account_model.dart';
import 'package:trackify/data/models/transaction_model.dart';

TransactionModel _tx(
  TransactionType type,
  double amount, {
  String? account,
  String? to,
}) =>
    TransactionModel(
      id: '${type.name}-$amount-$account-$to',
      amount: amount,
      type: type,
      categoryId: 'c',
      date: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      accountId: account,
      toAccountId: to,
    );

void main() {
  final bank = AccountModel(
      id: 'bank', name: 'Bank', openingBalance: 1000, isDefault: true);
  final cash = AccountModel(
      id: 'cash', name: 'Cash', type: AccountType.cash, openingBalance: 200);

  group('computeAccountBalances', () {
    test('starts from opening balances', () {
      final b =
          computeAccountBalances([bank, cash], [], defaultAccountId: 'bank');
      expect(b, {'bank': 1000.0, 'cash': 200.0});
      expect(totalBalance(b), 1200.0);
    });

    test('applies income and expense to the right account', () {
      final b = computeAccountBalances(
        [bank, cash],
        [
          _tx(TransactionType.income, 500, account: 'bank'),
          _tx(TransactionType.expense, 50, account: 'cash'),
        ],
        defaultAccountId: 'bank',
      );
      expect(b['bank'], 1500.0);
      expect(b['cash'], 150.0);
    });

    test('legacy entries without an account count toward the default', () {
      final b = computeAccountBalances(
        [bank, cash],
        [_tx(TransactionType.expense, 100)],
        defaultAccountId: 'bank',
      );
      expect(b['bank'], 900.0);
      expect(b['cash'], 200.0);
    });

    test('transfers move money between accounts', () {
      final b = computeAccountBalances(
        [bank, cash],
        [_tx(TransactionType.transfer, 300, account: 'bank', to: 'cash')],
        defaultAccountId: 'bank',
      );
      expect(b['bank'], 700.0);
      expect(b['cash'], 500.0);
      expect(totalBalance(b), 1200.0, reason: 'transfers never change total');
    });

    test('ignores transfers without a destination or to the same account', () {
      final b = computeAccountBalances(
        [bank, cash],
        [
          _tx(TransactionType.transfer, 300, account: 'bank'),
          _tx(TransactionType.transfer, 300, account: 'cash', to: 'cash'),
        ],
        defaultAccountId: 'bank',
      );
      expect(b, {'bank': 1000.0, 'cash': 200.0});
    });

    test('skips transactions pointing at a deleted account', () {
      final b = computeAccountBalances(
        [bank],
        [_tx(TransactionType.expense, 10, account: 'gone')],
        defaultAccountId: 'bank',
      );
      expect(b, {'bank': 1000.0});
    });
  });

  test('AccountModel round-trips through JSON', () {
    final a = AccountModel(
      id: 'x',
      name: 'Card',
      type: AccountType.card,
      openingBalance: -2500,
      colorHex: '#E84393',
      sortOrder: 3,
    );
    final back = AccountModel.fromJson(a.toJson());
    expect(back.type, AccountType.card);
    expect(back.openingBalance, -2500.0);
    expect(back.colorHex, '#E84393');
    expect(back.isDefault, isFalse);
  });
}
