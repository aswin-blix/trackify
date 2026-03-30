// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_sms_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BankSmsMessageAdapter extends TypeAdapter<BankSmsMessage> {
  @override
  final int typeId = 2;

  @override
  BankSmsMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BankSmsMessage(
      id: fields[0] as String,
      sender: fields[1] as String,
      rawBody: fields[2] as String,
      parsedAmount: fields[3] as double?,
      parsedType: fields[4] as String?,
      parsedMerchant: fields[5] as String?,
      parsedDate: fields[6] as DateTime?,
      status: fields[7] as SmsStatus,
      receivedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BankSmsMessage obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sender)
      ..writeByte(2)
      ..write(obj.rawBody)
      ..writeByte(3)
      ..write(obj.parsedAmount)
      ..writeByte(4)
      ..write(obj.parsedType)
      ..writeByte(5)
      ..write(obj.parsedMerchant)
      ..writeByte(6)
      ..write(obj.parsedDate)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.receivedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankSmsMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SmsStatusAdapter extends TypeAdapter<SmsStatus> {
  @override
  final int typeId = 5;

  @override
  SmsStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SmsStatus.pending;
      case 1:
        return SmsStatus.added;
      case 2:
        return SmsStatus.dismissed;
      default:
        return SmsStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SmsStatus obj) {
    switch (obj) {
      case SmsStatus.pending:
        writer.writeByte(0);
        break;
      case SmsStatus.added:
        writer.writeByte(1);
        break;
      case SmsStatus.dismissed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
