// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      userName: fields[0] as String,
      avatarPath: fields[1] as String?,
      currency: fields[2] as String,
      currencySymbol: fields[3] as String,
      themeMode: fields[4] as int,
      notificationEnabled: fields[5] as bool,
      notificationHour: fields[6] as int,
      notificationMinute: fields[7] as int,
      smsReaderEnabled: fields[8] as bool,
      knownSenderIds: (fields[9] as List?)?.cast<String>(),
      autoBackupEnabled: fields[10] as bool,
      autoBackupHour: fields[11] as int,
      autoBackupMinute: fields[12] as int,
      backupRetentionDays: fields[13] as int,
      appLockEnabled: fields[14] as bool,
      appLockType: fields[15] as String,
      onboardingComplete: fields[16] as bool,
      monthlyBudget: fields[17] as double?,
      lastBackupAt: fields[18] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.userName)
      ..writeByte(1)
      ..write(obj.avatarPath)
      ..writeByte(2)
      ..write(obj.currency)
      ..writeByte(3)
      ..write(obj.currencySymbol)
      ..writeByte(4)
      ..write(obj.themeMode)
      ..writeByte(5)
      ..write(obj.notificationEnabled)
      ..writeByte(6)
      ..write(obj.notificationHour)
      ..writeByte(7)
      ..write(obj.notificationMinute)
      ..writeByte(8)
      ..write(obj.smsReaderEnabled)
      ..writeByte(9)
      ..write(obj.knownSenderIds)
      ..writeByte(10)
      ..write(obj.autoBackupEnabled)
      ..writeByte(11)
      ..write(obj.autoBackupHour)
      ..writeByte(12)
      ..write(obj.autoBackupMinute)
      ..writeByte(13)
      ..write(obj.backupRetentionDays)
      ..writeByte(14)
      ..write(obj.appLockEnabled)
      ..writeByte(15)
      ..write(obj.appLockType)
      ..writeByte(16)
      ..write(obj.onboardingComplete)
      ..writeByte(17)
      ..write(obj.monthlyBudget)
      ..writeByte(18)
      ..write(obj.lastBackupAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
