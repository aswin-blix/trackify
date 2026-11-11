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
  // Savings and investments. Appended so existing Hive indexes stay valid.
  @HiveField(5)
  fixedDeposit,
  @HiveField(6)
  mutualFund,
  @HiveField(7)
  stocks,
  @HiveField(8)
  chit,
  // A loan or EMI plan: a liability whose balance is minus what is owed.
  @HiveField(9)
  loan,
}

extension AccountTypeX on AccountType {
  String get label => switch (this) {
        AccountType.cash => 'Cash',
        AccountType.bank => 'Bank',
        AccountType.wallet => 'UPI / Wallet',
        AccountType.card => 'Credit Card',
        AccountType.other => 'Other',
        AccountType.fixedDeposit => 'Fixed Deposit',
        AccountType.mutualFund => 'Mutual Fund',
        AccountType.stocks => 'Stocks',
        AccountType.chit => 'Chit / Kuri',
        AccountType.loan => 'Loan / EMI',
      };

  IconData get icon => switch (this) {
        AccountType.cash => Icons.payments_rounded,
        AccountType.bank => Icons.account_balance_rounded,
        AccountType.wallet => Icons.account_balance_wallet_rounded,
        AccountType.card => Icons.credit_card_rounded,
        AccountType.other => Icons.savings_rounded,
        AccountType.fixedDeposit => Icons.lock_clock_rounded,
        AccountType.mutualFund => Icons.pie_chart_rounded,
        AccountType.stocks => Icons.candlestick_chart_rounded,
        AccountType.chit => Icons.groups_rounded,
        AccountType.loan => Icons.request_quote_rounded,
      };

  /// Savings and investments: shown under "Invested", not as money you can
  /// spend, and valued by `investmentValue` rather than the plain balance.
  bool get isInvestment => switch (this) {
        AccountType.fixedDeposit ||
        AccountType.mutualFund ||
        AccountType.stocks ||
        AccountType.chit =>
          true,
        _ => false,
      };

  /// A loan or EMI plan. Not spendable money and not an investment; it
  /// lowers net worth by what is still owed.
  bool get isLoan => this == AccountType.loan;

  /// Balance is entered as an amount owed and stored negative.
  bool get isLiabilityEntry => this == AccountType.card || isLoan;

  /// Value is typed in by the user from their broker or fund app.
  bool get hasMarketValue =>
      this == AccountType.mutualFund || this == AccountType.stocks;
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

  // ── Investment details. All optional; unused by everyday accounts. ──

  /// Fixed deposit or loan: annual interest rate in percent, e.g. 7.1.
  @HiveField(7)
  double? interestRate;

  /// Fixed deposit: date the deposit was opened. Chit: month 1.
  @HiveField(8)
  DateTime? startDate;

  /// Fixed deposit: date it matures; interest stops growing after this.
  @HiveField(9)
  DateTime? maturityDate;

  /// Mutual fund / stocks: the portfolio value last typed in.
  @HiveField(10)
  double? marketValue;

  /// When [marketValue] was entered.
  @HiveField(11)
  DateTime? valueUpdatedAt;

  /// Amount invested at the moment [marketValue] was entered. Money added
  /// afterwards (the next SIP) is counted at face value until the next
  /// update, so a deposit never shows up as a loss.
  @HiveField(12)
  double? valuedInvested;

  /// Chit: the full chit amount (sala), e.g. 1,00,000.
  @HiveField(13)
  double? chitAmount;

  /// Chit: how many monthly instalments it runs for.
  @HiveField(14)
  int? chitMonths;

  /// Loan: the monthly EMI, used to estimate how many are left.
  @HiveField(15)
  double? emiAmount;

  AccountModel({
    required this.id,
    required this.name,
    this.type = AccountType.bank,
    this.openingBalance = 0,
    this.colorHex = '#6C63FF',
    this.sortOrder = 0,
    this.isDefault = false,
    this.interestRate,
    this.startDate,
    this.maturityDate,
    this.marketValue,
    this.valueUpdatedAt,
    this.valuedInvested,
    this.chitAmount,
    this.chitMonths,
    this.emiAmount,
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
      interestRate: interestRate,
      startDate: startDate,
      maturityDate: maturityDate,
      marketValue: marketValue,
      valueUpdatedAt: valueUpdatedAt,
      valuedInvested: valuedInvested,
      chitAmount: chitAmount,
      chitMonths: chitMonths,
      emiAmount: emiAmount,
    );
  }

  /// Records a new market value against what has been invested so far.
  AccountModel withMarketValue(double value, double invested, DateTime at) =>
      copyWith()
        ..marketValue = value
        ..valuedInvested = invested
        ..valueUpdatedAt = at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'openingBalance': openingBalance,
        'colorHex': colorHex,
        'sortOrder': sortOrder,
        'isDefault': isDefault,
        if (interestRate != null) 'interestRate': interestRate,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (maturityDate != null)
          'maturityDate': maturityDate!.toIso8601String(),
        if (marketValue != null) 'marketValue': marketValue,
        if (valueUpdatedAt != null)
          'valueUpdatedAt': valueUpdatedAt!.toIso8601String(),
        if (valuedInvested != null) 'valuedInvested': valuedInvested,
        if (chitAmount != null) 'chitAmount': chitAmount,
        if (chitMonths != null) 'chitMonths': chitMonths,
        if (emiAmount != null) 'emiAmount': emiAmount,
      };

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
  static double? _num(Object? v) => (v as num?)?.toDouble();

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
      interestRate: _num(json['interestRate']),
      startDate: _date(json['startDate']),
      maturityDate: _date(json['maturityDate']),
      marketValue: _num(json['marketValue']),
      valueUpdatedAt: _date(json['valueUpdatedAt']),
      valuedInvested: _num(json['valuedInvested']),
      chitAmount: _num(json['chitAmount']),
      chitMonths: (json['chitMonths'] as num?)?.toInt(),
      emiAmount: _num(json['emiAmount']),
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
