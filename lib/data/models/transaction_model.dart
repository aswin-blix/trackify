import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: kTransactionTypeEnumId)
enum TransactionType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
  @HiveField(2)
  transfer,

  // ── Lent & borrowed ─────────────────────────────────────────────────────
  // These move money between an account and a person. They change account
  // balances but are never income or expense. Append only: Hive stores the
  // index.

  /// Money you gave someone; they owe you.
  @HiveField(3)
  lend,

  /// Money someone gave you; you owe them.
  @HiveField(4)
  borrow,

  /// Someone paid you back.
  @HiveField(5)
  collect,

  /// You paid someone back.
  @HiveField(6)
  repay,
}

extension TransactionTypeDebt on TransactionType {
  bool get isDebt => switch (this) {
        TransactionType.lend ||
        TransactionType.borrow ||
        TransactionType.collect ||
        TransactionType.repay =>
          true,
        _ => false,
      };

  /// True when money comes into the account.
  bool get isInflow => switch (this) {
        TransactionType.income ||
        TransactionType.borrow ||
        TransactionType.collect =>
          true,
        _ => false,
      };
}

@HiveType(typeId: kTransactionTypeId)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  String note;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  String? receiptImagePath;

  @HiveField(8)
  bool isFromSms;

  @HiveField(9)
  String? smsSource;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  /// Firebase uid of the household member who added this entry. Null for
  /// entries made before shared tracking was enabled on this device.
  @HiveField(12)
  String? addedBy;

  /// Account the money left (expense, transfer) or entered (income). Null
  /// means the default account, which keeps pre-accounts data valid.
  @HiveField(13)
  String? accountId;

  /// Destination account; only set for transfers.
  @HiveField(14)
  String? toAccountId;

  /// The other person in a lend/borrow/collect/repay entry.
  @HiveField(15)
  String? counterparty;

  /// When a lend or borrow is expected to be paid back.
  @HiveField(16)
  DateTime? dueDate;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note = '',
    List<String>? tags,
    required this.date,
    this.receiptImagePath,
    this.isFromSms = false,
    this.smsSource,
    required this.createdAt,
    required this.updatedAt,
    this.addedBy,
    this.accountId,
    this.toAccountId,
    this.counterparty,
    this.dueDate,
  }) : tags = tags ?? [];

  TransactionModel copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? note,
    List<String>? tags,
    DateTime? date,
    String? receiptImagePath,
    bool? isFromSms,
    String? smsSource,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? addedBy,
    String? accountId,
    String? toAccountId,
    String? counterparty,
    DateTime? dueDate,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isFromSms: isFromSms ?? this.isFromSms,
      smsSource: smsSource ?? this.smsSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      addedBy: addedBy ?? this.addedBy,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      counterparty: counterparty ?? this.counterparty,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'note': note,
        'tags': tags,
        'date': date.toIso8601String(),
        'receiptImagePath': receiptImagePath,
        'isFromSms': isFromSms,
        'smsSource': smsSource,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'addedBy': addedBy,
        'accountId': accountId,
        'toAccountId': toAccountId,
        if (counterparty != null) 'counterparty': counterparty,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: json['categoryId'] as String,
      note: json['note'] as String? ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      date: DateTime.parse(json['date'] as String),
      receiptImagePath: json['receiptImagePath'] as String?,
      isFromSms: json['isFromSms'] as bool? ?? false,
      smsSource: json['smsSource'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      addedBy: json['addedBy'] as String?,
      accountId: json['accountId'] as String?,
      toAccountId: json['toAccountId'] as String?,
      counterparty: json['counterparty'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
    );
  }
}
