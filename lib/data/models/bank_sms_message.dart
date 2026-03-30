import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'bank_sms_message.g.dart';

@HiveType(typeId: kSmsStatusEnumId)
enum SmsStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  added,
  @HiveField(2)
  dismissed,
}

@HiveType(typeId: kBankSmsMessageTypeId)
class BankSmsMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String sender;

  @HiveField(2)
  String rawBody;

  @HiveField(3)
  double? parsedAmount;

  @HiveField(4)
  String? parsedType; // 'debit' | 'credit'

  @HiveField(5)
  String? parsedMerchant;

  @HiveField(6)
  DateTime? parsedDate;

  @HiveField(7)
  SmsStatus status;

  @HiveField(8)
  DateTime receivedAt;

  BankSmsMessage({
    required this.id,
    required this.sender,
    required this.rawBody,
    this.parsedAmount,
    this.parsedType,
    this.parsedMerchant,
    this.parsedDate,
    this.status = SmsStatus.pending,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'rawBody': rawBody,
        'parsedAmount': parsedAmount,
        'parsedType': parsedType,
        'parsedMerchant': parsedMerchant,
        'parsedDate': parsedDate?.toIso8601String(),
        'status': status.name,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory BankSmsMessage.fromJson(Map<String, dynamic> json) {
    return BankSmsMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      rawBody: json['rawBody'] as String,
      parsedAmount: (json['parsedAmount'] as num?)?.toDouble(),
      parsedType: json['parsedType'] as String?,
      parsedMerchant: json['parsedMerchant'] as String?,
      parsedDate: json['parsedDate'] != null
          ? DateTime.parse(json['parsedDate'] as String)
          : null,
      status: SmsStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SmsStatus.pending,
      ),
      receivedAt: DateTime.parse(json['receivedAt'] as String),
    );
  }
}
