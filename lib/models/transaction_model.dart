class TransactionModel {
  final int? id;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final int categoryId;
  final String? notes;

  TransactionModel({
    this.id,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.categoryId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'is_expense': isExpense ? 1 : 0,
      'category_id': categoryId,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      isExpense: map['is_expense'] == 1,
      categoryId: map['category_id'],
      notes: map['notes'],
    );
  }
}
