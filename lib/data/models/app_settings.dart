import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'app_settings.g.dart';

@HiveType(typeId: kAppSettingsTypeId)
class AppSettings extends HiveObject {
  @HiveField(0)
  String userName;

  @HiveField(1)
  String? avatarPath;

  @HiveField(2)
  String currency; // 'INR', 'USD', etc.

  @HiveField(3)
  String currencySymbol; // '₹', '$', etc.

  @HiveField(4)
  int themeMode; // 0=system, 1=light, 2=dark

  @HiveField(5)
  bool notificationEnabled;

  @HiveField(6)
  int notificationHour;

  @HiveField(7)
  int notificationMinute;

  @HiveField(8)
  bool smsReaderEnabled;

  @HiveField(9)
  List<String> knownSenderIds;

  @HiveField(10)
  bool autoBackupEnabled;

  @HiveField(11)
  int autoBackupHour;

  @HiveField(12)
  int autoBackupMinute;

  @HiveField(13)
  int backupRetentionDays;

  @HiveField(14)
  bool appLockEnabled;

  @HiveField(15)
  String appLockType; // 'pin' | 'biometric'

  @HiveField(16)
  bool onboardingComplete;

  @HiveField(17)
  double? monthlyBudget;

  @HiveField(18)
  DateTime? lastBackupAt;

  AppSettings({
    this.userName = '',
    this.avatarPath,
    this.currency = 'INR',
    this.currencySymbol = '₹',
    this.themeMode = 0,
    this.notificationEnabled = true,
    this.notificationHour = 21,
    this.notificationMinute = 0,
    this.smsReaderEnabled = false,
    List<String>? knownSenderIds,
    this.autoBackupEnabled = false,
    this.autoBackupHour = 23,
    this.autoBackupMinute = 0,
    this.backupRetentionDays = 14,
    this.appLockEnabled = false,
    this.appLockType = 'biometric',
    this.onboardingComplete = false,
    this.monthlyBudget,
    this.lastBackupAt,
  }) : knownSenderIds = knownSenderIds ?? List.from(kDefaultBankSenders);

  ThemeMode get resolvedThemeMode {
    switch (themeMode) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'avatarPath': avatarPath,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'themeMode': themeMode,
        'notificationEnabled': notificationEnabled,
        'notificationHour': notificationHour,
        'notificationMinute': notificationMinute,
        'smsReaderEnabled': smsReaderEnabled,
        'knownSenderIds': knownSenderIds,
        'autoBackupEnabled': autoBackupEnabled,
        'autoBackupHour': autoBackupHour,
        'autoBackupMinute': autoBackupMinute,
        'backupRetentionDays': backupRetentionDays,
        'appLockEnabled': appLockEnabled,
        'appLockType': appLockType,
        'onboardingComplete': onboardingComplete,
        'monthlyBudget': monthlyBudget,
        'lastBackupAt': lastBackupAt?.toIso8601String(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      userName: json['userName'] as String? ?? '',
      avatarPath: json['avatarPath'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      currencySymbol: json['currencySymbol'] as String? ?? '₹',
      themeMode: json['themeMode'] as int? ?? 0,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      notificationHour: json['notificationHour'] as int? ?? 21,
      notificationMinute: json['notificationMinute'] as int? ?? 0,
      smsReaderEnabled: json['smsReaderEnabled'] as bool? ?? false,
      knownSenderIds:
          (json['knownSenderIds'] as List?)?.cast<String>() ??
              List.from(kDefaultBankSenders),
      autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? false,
      autoBackupHour: json['autoBackupHour'] as int? ?? 23,
      autoBackupMinute: json['autoBackupMinute'] as int? ?? 0,
      backupRetentionDays: json['backupRetentionDays'] as int? ?? 14,
      appLockEnabled: json['appLockEnabled'] as bool? ?? false,
      appLockType: json['appLockType'] as String? ?? 'biometric',
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble(),
      lastBackupAt: json['lastBackupAt'] != null
          ? DateTime.parse(json['lastBackupAt'] as String)
          : null,
    );
  }
}
