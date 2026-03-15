import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _categories = await DatabaseHelper.instance.readAllCategories();
    _transactions = await DatabaseHelper.instance.readAllTransactions();

    _isLoading = false;
    notifyListeners();
  }

  // --- Categories ---
  Future<void> addCategory(CategoryModel category) async {
    await DatabaseHelper.instance.createCategory(category);
    await loadData(); // Reload to get newly assigned autoincrement ID
  }

  Future<void> updateCategory(CategoryModel category) async {
    await DatabaseHelper.instance.updateCategory(category);
    await loadData();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    await loadData();
  }

  CategoryModel? getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  // --- Transactions ---
  Future<void> addTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.createTransaction(transaction);
    await loadData();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.updateTransaction(transaction);
    await loadData();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadData();
  }

  // --- Analytics & Calculations ---
  
  double get totalExpenses {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalIncome {
    return _transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }
  
  double get balance => totalIncome - totalExpenses;

  double getMonthlyTotal(int year, int month, {bool isExpense = true}) {
    return _transactions
        .where((t) =>
            t.isExpense == isExpense &&
            t.date.year == year &&
            t.date.month == month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> clearAllTransactions() async {
    await DatabaseHelper.instance.clearAllTransactions();
    await loadData();
  }

  /// Groups expenses by category for a specific month/year.
  /// Useful for pie charts or breakdown lists.
  Map<int, double> getExpensesByCategory(int year, int month) {
    Map<int, double> groupedData = {};
    
    final monthlyExpenses = _transactions.where((t) => 
      t.isExpense && 
      t.date.year == year && 
      t.date.month == month
    );

    for (var transaction in monthlyExpenses) {
      if (groupedData.containsKey(transaction.categoryId)) {
        groupedData[transaction.categoryId] = groupedData[transaction.categoryId]! + transaction.amount;
      } else {
        groupedData[transaction.categoryId] = transaction.amount;
      }
    }

    return groupedData;
  }
}
