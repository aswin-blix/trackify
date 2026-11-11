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
      interestRate: fields[7] as double?,
      startDate: fields[8] as DateTime?,
      maturityDate: fields[9] as DateTime?,
      marketValue: fields[10] as double?,
      valueUpdatedAt: fields[11] as DateTime?,
      valuedInvested: fields[12] as double?,
      chitAmount: fields[13] as double?,
      chitMonths: fields[14] as int?,
      emiAmount: fields[15] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.isDefault)
      ..writeByte(7)
      ..write(obj.interestRate)
      ..writeByte(8)
      ..write(obj.startDate)
      ..writeByte(9)
      ..write(obj.maturityDate)
      ..writeByte(10)
      ..write(obj.marketValue)
      ..writeByte(11)
      ..write(obj.valueUpdatedAt)
      ..writeByte(12)
      ..write(obj.valuedInvested)
      ..writeByte(13)
      ..write(obj.chitAmount)
      ..writeByte(14)
      ..write(obj.chitMonths)
      ..writeByte(15)
      ..write(obj.emiAmount);
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
      case 5:
        return AccountType.fixedDeposit;
      case 6:
        return AccountType.mutualFund;
      case 7:
        return AccountType.stocks;
      case 8:
        return AccountType.chit;
      case 9:
        return AccountType.loan;
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
      case AccountType.fixedDeposit:
        writer.writeByte(5);
        break;
      case AccountType.mutualFund:
        writer.writeByte(6);
        break;
      case AccountType.stocks:
        writer.writeByte(7);
        break;
      case AccountType.chit:
        writer.writeByte(8);
        break;
      case AccountType.loan:
        writer.writeByte(9);
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
