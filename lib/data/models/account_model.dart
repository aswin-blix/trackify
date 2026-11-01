import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'account_model.g.dart';

@HiveType(typeId: kAccountTypeEnumId)
enum AccountType {
  @HiveField(0)
  cash,
  @HiveField(1)
  bank,
  @HiveField(2)
  wallet,
  @HiveField(3)
  card,
  @HiveField(4)
  other,
}

extension AccountTypeX on AccountType {
  String get label => switch (this) {
        AccountType.cash => 'Cash',
        AccountType.bank => 'Bank',
        AccountType.wallet => 'UPI / Wallet',
        AccountType.card => 'Credit Card',
        AccountType.other => 'Other',
      };

  IconData get icon => switch (this) {
        AccountType.cash => Icons.payments_rounded,
        AccountType.bank => Icons.account_balance_rounded,
        AccountType.wallet => Icons.account_balance_wallet_rounded,
        AccountType.card => Icons.credit_card_rounded,
        AccountType.other => Icons.savings_rounded,
      };
}

/// Where money sits: cash in hand, a bank account, a wallet, a card.
///
/// An account's balance is never stored. It is derived from
/// [openingBalance] plus every transaction that touches it (see
/// `computeAccountBalances`). Transactions with a null `accountId` belong to
/// the default account, which keeps data from before accounts existed valid.
@HiveType(typeId: kAccountTypeId)
class AccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  AccountType type;

  /// Balance on the day the user started tracking in this account.
  @HiveField(3)
  double openingBalance;

  @HiveField(4)
  String colorHex;

  @HiveField(5)
  int sortOrder;

  /// Pre-selected when adding a transaction; also owns legacy entries that
  /// have no account. Exactly one account should be the default.
  @HiveField(6)
  bool isDefault;

  AccountModel({
    required this.id,
    required this.name,
    this.type = AccountType.bank,
    this.openingBalance = 0,
    this.colorHex = '#6C63FF',
    this.sortOrder = 0,
    this.isDefault = false,
  });

  Color get color =>
      Color(int.parse(colorHex.replaceFirst('#', 'FF'), radix: 16));

  IconData get icon => type.icon;

  AccountModel copyWith({
    String? name,
    AccountType? type,
    double? openingBalance,
    String? colorHex,
    int? sortOrder,
    bool? isDefault,
  }) {
    return AccountModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'openingBalance': openingBalance,
        'colorHex': colorHex,
        'sortOrder': sortOrder,
        'isDefault': isDefault,
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccountType.other,
      ),
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      colorHex: json['colorHex'] as String? ?? '#6C63FF',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

/// Seeded on first run and after "Clear all data". Fixed ids so two phones
/// that join a household share the same two starter accounts.
List<AccountModel> get defaultAccounts => [
      AccountModel(
        id: kDefaultAccountId,
        name: 'Bank',
        type: AccountType.bank,
        colorHex: '#6C63FF',
        sortOrder: 0,
        isDefault: true,
      ),
      AccountModel(
        id: kCashAccountId,
        name: 'Cash',
        type: AccountType.cash,
        colorHex: '#00B87C',
        sortOrder: 1,
      ),
    ];
