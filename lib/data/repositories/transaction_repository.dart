import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../../core/constants/app_constants.dart';

class TransactionRepository {
  Box<TransactionModel> get _box => Hive.box<TransactionModel>(kTransactionsBox);

  List<TransactionModel> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<TransactionModel> getByDateRange(DateTime from, DateTime to) {
    return _box.values
        .where((t) =>
            t.date.isAfter(from.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(to.add(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> getThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return getByDateRange(start, end);
  }

  List<TransactionModel> getToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getByDateRange(start, end);
  }

  List<TransactionModel> getLast7Days() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    return getByDateRange(
      DateTime(start.year, start.month, start.day),
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  TransactionModel? getById(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(TransactionModel transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> update(TransactionModel transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }

  double getTotalIncome({DateTime? from, DateTime? to}) {
    final transactions = from != null && to != null
        ? getByDateRange(from, to)
        : getAll();
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpense({DateTime? from, DateTime? to}) {
    final transactions = from != null && to != null
        ? getByDateRange(from, to)
        : getAll();
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getExpenseByCategory({DateTime? from, DateTime? to}) {
    final transactions = from != null && to != null
        ? getByDateRange(from, to)
        : getThisMonth();
    final result = <String, double>{};
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
    }
    return result;
  }

  /// Daily spending for last N days
  Map<DateTime, double> getDailySpending(int days) {
    final now = DateTime.now();
    final result = <DateTime, double>{};
    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      result[DateTime(day.year, day.month, day.day)] = 0;
    }
    for (final t in getLast7Days()) {
      if (t.type == TransactionType.expense) {
        final key = DateTime(t.date.year, t.date.month, t.date.day);
        result[key] = (result[key] ?? 0) + t.amount;
      }
    }
    return result;
  }

  ValueListenable<Box<TransactionModel>> get listenable => _box.listenable();
}
