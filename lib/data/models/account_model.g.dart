// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountModelAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = 7;

  @override
  AccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as AccountType,
      openingBalance: fields[3] as double,
      colorHex: fields[4] as String,
      sortOrder: fields[5] as int,
      isDefault: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.openingBalance)
      ..writeByte(4)
      ..write(obj.colorHex)
      ..writeByte(5)
      ..write(obj.sortOrder)
      ..writeByte(6)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 8;

  @override
  AccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountType.cash;
      case 1:
        return AccountType.bank;
      case 2:
        return AccountType.wallet;
      case 3:
        return AccountType.card;
      case 4:
        return AccountType.other;
      default:
        return AccountType.cash;
    }
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    switch (obj) {
      case AccountType.cash:
        writer.writeByte(0);
        break;
      case AccountType.bank:
        writer.writeByte(1);
        break;
      case AccountType.wallet:
        writer.writeByte(2);
        break;
      case AccountType.card:
        writer.writeByte(3);
        break;
      case AccountType.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
