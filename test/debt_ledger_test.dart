import 'package:flutter_test/flutter_test.dart';
import 'package:trackify/core/utils/balance_calculator.dart';
import 'package:trackify/core/utils/debt_ledger.dart';
import 'package:trackify/data/models/account_model.dart';
import 'package:trackify/data/models/transaction_model.dart';

var _seq = 0;
TransactionModel tx(
  TransactionType type,
  double amount,
  String who, {
  required DateTime date,
  String? by,
  DateTime? due,
  String account = 'bank',
}) =>
    TransactionModel(
      id: 't${_seq++}',
      amount: amount,
      type: type,
      categoryId: 'debt',
      date: date,
      createdAt: date,
      updatedAt: date,
      addedBy: by,
      accountId: account,
      counterparty: who,
      dueDate: due,
    );

void main() {
  final d1 = DateTime(2026, 10, 1);
  final d2 = DateTime(2026, 10, 10);
  final d3 = DateTime(2026, 10, 20);
  String owner(TransactionModel t) => t.addedBy ?? 'me';

  test('partial repayment leaves the rest owed', () {
    final b = DebtLedger.balances([
      tx(TransactionType.lend, 2000, 'Rahul', date: d1),
      tx(TransactionType.collect, 500, 'rahul ', date: d2),
    ], ownerOf: owner);
    expect(b, hasLength(1));
    expect(b.single.net, 1500);
    expect(b.single.theyOwe, isTrue);
    expect(b.single.name, 'Rahul');
  });

  test('borrowing and repaying in full settles', () {
    final b = DebtLedger.balances([
      tx(TransactionType.borrow, 800, 'Shyam', date: d1),
      tx(TransactionType.repay, 800, 'Shyam', date: d2),
    ], ownerOf: owner);
    expect(b.single.isSettled, isTrue);
  });

  test('each owner keeps a separate balance with the same person', () {
    final b = DebtLedger.balances([
      tx(TransactionType.lend, 1000, 'Anu', date: d1, by: 'me'),
      tx(TransactionType.borrow, 300, 'Anu', date: d1, by: 'partner'),
    ], ownerOf: owner);
    expect(b, hasLength(2));
    final mine = b.firstWhere((p) => p.owner == 'me');
    final theirs = b.firstWhere((p) => p.owner == 'partner');
    expect(mine.net, 1000);
    expect(theirs.net, -300);
    final t = DebtLedger.totals(b.where((p) => p.owner == 'me'));
    expect(t.owedToYou, 1000);
    expect(t.youOwe, 0);
  });

  test('due date resets once the balance is cleared', () {
    final b = DebtLedger.balances([
      tx(TransactionType.lend, 500, 'Ravi',
          date: d1, due: DateTime(2026, 10, 5)),
      tx(TransactionType.collect, 500, 'Ravi', date: d2),
      tx(TransactionType.lend, 200, 'Ravi',
          date: d3, due: DateTime(2026, 12, 1)),
    ], ownerOf: owner);
    expect(b.single.net, 200);
    expect(b.single.dueDate, DateTime(2026, 12, 1));
    expect(b.single.isOverdue(DateTime(2026, 11, 2)), isFalse);
    expect(b.single.isOverdue(DateTime(2026, 12, 2)), isTrue);
  });

  test('open balances sort before settled ones', () {
    final b = DebtLedger.balances([
      tx(TransactionType.lend, 100, 'A', date: d1),
      tx(TransactionType.collect, 100, 'A', date: d2),
      tx(TransactionType.lend, 50, 'B', date: d1),
    ], ownerOf: owner);
    expect(b.first.name, 'B');
    expect(b.last.isSettled, isTrue);
  });

  test('loans move account balances but are not income or expense', () {
    final bank = AccountModel(
      id: 'bank',
      name: 'Bank',
      openingBalance: 10000,
      isDefault: true,
    );
    final balances = computeAccountBalances(
      [bank],
      [
        tx(TransactionType.lend, 2000, 'X', date: d1),
        tx(TransactionType.collect, 500, 'X', date: d2),
        tx(TransactionType.borrow, 1000, 'Y', date: d2),
        tx(TransactionType.repay, 400, 'Y', date: d3),
      ],
      defaultAccountId: 'bank',
    );
    expect(balances['bank'], 10000 - 2000 + 500 + 1000 - 400);
    expect(TransactionType.lend.isDebt, isTrue);
    expect(TransactionType.expense.isDebt, isFalse);
  });

  test('counterparty and due date survive JSON', () {
    final t = tx(TransactionType.lend, 10, 'Z',
        date: d1, due: DateTime(2026, 11, 30));
    final back = TransactionModel.fromJson(t.toJson());
    expect(back.type, TransactionType.lend);
    expect(back.counterparty, 'Z');
    expect(back.dueDate, DateTime(2026, 11, 30));
  });
}
