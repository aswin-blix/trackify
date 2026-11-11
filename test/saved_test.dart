import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/utils/investments.dart';
import 'package:trackify/data/models/account_model.dart';
import 'package:trackify/data/models/transaction_model.dart';

int _n = 0;
TransactionModel _tx(TransactionType type, double amount,
        {String? from, String? to, DateTime? date}) =>
    TransactionModel(
      id: 't${_n++}',
      amount: amount,
      type: type,
      categoryId: 'c',
      date: date ?? DateTime(2026, 11, 5),
      createdAt: DateTime(2026, 11, 5),
      updatedAt: DateTime(2026, 11, 5),
      accountId: from,
      toAccountId: to,
    );

void main() {
  final accounts = [
    AccountModel(id: 'bank', name: 'Bank', isDefault: true),
    AccountModel(id: 'cash', name: 'Cash', type: AccountType.cash),
    AccountModel(id: 'wife', name: 'Wife SBI'),
    AccountModel(id: 'sip', name: 'SIP', type: AccountType.mutualFund),
    AccountModel(id: 'fd', name: 'FD', type: AccountType.fixedDeposit),
    AccountModel(id: 'kuri', name: 'Kuri', type: AccountType.chit),
    AccountModel(id: 'car', name: 'Car', type: AccountType.loan),
  ];

  double saved(List<TransactionModel> txs) => savedBetween(
        accounts,
        txs,
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 30, 23, 59, 59),
        defaultAccountId: 'bank',
      );

  test('money into investments, chits and loan principal counts', () {
    expect(
      saved([
        _tx(TransactionType.transfer, 5000, from: 'bank', to: 'sip'),
        _tx(TransactionType.transfer, 2000, from: 'cash', to: 'kuri'),
        _tx(TransactionType.transfer, 6250, from: 'bank', to: 'car'),
      ]),
      13250,
    );
  });

  test('legacy transfers without a source come from the default account', () {
    expect(saved([_tx(TransactionType.transfer, 1000, to: 'fd')]), 1000);
  });

  test('withdrawals count down; moves between savings do not count', () {
    expect(
      saved([
        _tx(TransactionType.transfer, 5000, from: 'bank', to: 'sip'),
        _tx(TransactionType.transfer, 8000, from: 'fd', to: 'bank'),
        _tx(TransactionType.transfer, 3000, from: 'fd', to: 'sip'),
      ]),
      -3000,
    );
  });

  test('everyday transfers, income, spending and interest are ignored', () {
    expect(
      saved([
        _tx(TransactionType.transfer, 10000, from: 'bank', to: 'wife'),
        _tx(TransactionType.transfer, 2000, from: 'bank', to: 'cash'),
        _tx(TransactionType.income, 60000, from: 'bank'),
        _tx(TransactionType.expense, 3750, from: 'bank'),
      ]),
      0,
    );
  });

  test('only this month counts', () {
    expect(
      saved([
        _tx(TransactionType.transfer, 5000,
            from: 'bank', to: 'sip', date: DateTime(2026, 10, 31)),
        _tx(TransactionType.transfer, 5000,
            from: 'bank', to: 'sip', date: DateTime(2026, 12, 1)),
        _tx(TransactionType.transfer, 4000,
            from: 'bank', to: 'sip', date: DateTime(2026, 11, 30, 20)),
      ]),
      4000,
    );
  });
}
