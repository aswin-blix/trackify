import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/recurrence.dart';
import 'transaction_model.dart';

/// A rule that posts a transaction on a schedule. Occurrences are numbered
/// from 0 at [startDate]; [postedCount] is how many have been handled
/// (posted, or skipped while paused), so the next one is index
/// [postedCount].
class RecurringModel extends HiveObject {
  final String id;
  double amount;
  TransactionType type;
  String categoryId;
  String note;
  List<String> tags;
  String? accountId;
  String? toAccountId;
  RecurrenceFrequency frequency;
  int interval;
  DateTime startDate;
  DateTime? endDate;
  int postedCount;
  bool active;
  DateTime createdAt;
  DateTime updatedAt;

  RecurringModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note = '',
    List<String>? tags,
    this.accountId,
    this.toAccountId,
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    this.postedCount = 0,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  }) : tags = tags ?? [];

  DateTime occurrence(int index) =>
      Recurrence.occurrence(startDate, frequency, index, interval: interval);

  DateTime get nextDate => occurrence(postedCount);

  bool get isFinished => endDate != null && nextDate.isAfter(endDate!);

  /// Stable id for the transaction posted for occurrence [index], so a
  /// second pass (or a restore) can never post the same occurrence twice.
  String transactionIdFor(int index) => 'rec_${id}_$index';

  TransactionModel buildTransaction(int index, {DateTime? now}) {
    final stamp = now ?? DateTime.now();
    return TransactionModel(
      id: transactionIdFor(index),
      amount: amount,
      type: type,
      categoryId: categoryId,
      note: note,
      tags: List.of(tags),
      date: occurrence(index),
      createdAt: stamp,
      updatedAt: stamp,
      accountId: accountId,
      toAccountId: type == TransactionType.transfer ? toAccountId : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'note': note,
        'tags': tags,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'frequency': frequency.name,
        'interval': interval,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'postedCount': postedCount,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RecurringModel.fromJson(Map<String, dynamic> json) {
    return RecurringModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: json['categoryId'] as String,
      note: json['note'] as String? ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      accountId: json['accountId'] as String?,
      toAccountId: json['toAccountId'] as String?,
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      postedCount: (json['postedCount'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Hand-written to match the generated adapters' format; field numbers are
/// permanent, only append new ones.
class RecurringModelAdapter extends TypeAdapter<RecurringModel> {
  @override
  final int typeId = kRecurringTypeId;

  @override
  RecurringModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final freqIndex = (fields[8] as int?) ?? RecurrenceFrequency.monthly.index;
    return RecurringModel(
      id: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      type: fields[2] as TransactionType,
      categoryId: fields[3] as String,
      note: fields[4] as String? ?? '',
      tags: (fields[5] as List?)?.cast<String>(),
      accountId: fields[6] as String?,
      toAccountId: fields[7] as String?,
      frequency: freqIndex < RecurrenceFrequency.values.length
          ? RecurrenceFrequency.values[freqIndex]
          : RecurrenceFrequency.monthly,
      interval: fields[9] as int? ?? 1,
      startDate: fields[10] as DateTime,
      endDate: fields[11] as DateTime?,
      postedCount: fields[12] as int? ?? 0,
      active: fields[13] as bool? ?? true,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.accountId)
      ..writeByte(7)
      ..write(obj.toAccountId)
      ..writeByte(8)
      ..write(obj.frequency.index)
      ..writeByte(9)
      ..write(obj.interval)
      ..writeByte(10)
      ..write(obj.startDate)
      ..writeByte(11)
      ..write(obj.endDate)
      ..writeByte(12)
      ..write(obj.postedCount)
      ..writeByte(13)
      ..write(obj.active)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringModelAdapter && runtimeType == other.runtimeType;
}
