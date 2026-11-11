import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/investments.dart';
import '../../core/utils/loans.dart';
import '../../data/models/account_model.dart';
import '../../shared/providers/app_providers.dart';

const _palette = [
  Color(0xFF6C63FF),
  Color(0xFF00B87C),
  Color(0xFF0984E3),
  Color(0xFFFF8E53),
  Color(0xFFE84393),
  Color(0xFF00CEC9),
  Color(0xFFFDCB6E),
  Color(0xFFE8365D),
  Color(0xFF636E72),
];

/// Lists accounts with live balances; add, edit, delete, set default.
/// Savings and investments are listed separately with their current value.
class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);
    final balances = ref.watch(accountBalancesProvider);
    final values = ref.watch(accountValuesProvider);
    final portfolio = ref.watch(portfolioProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;

    final everyday =
        accounts.where((a) => !a.type.isInvestment && !a.type.isLoan).toList();
    final invest = accounts.where((a) => a.type.isInvestment).toList();
    final loans = accounts.where((a) => a.type.isLoan).toList();

    Widget tile(AccountModel a, int i) {
      final invested = balances[a.id] ?? a.openingBalance;
      return _AccountTile(
        account: a,
        invested: invested,
        value: values[a.id] ?? invested,
        symbol: symbol,
        onTap: () => _showSheet(context, a),
        onUpdateValue: a.type.hasMarketValue
            ? () => _showUpdateValue(context, ref, a, invested)
            : null,
        onSetDefault: a.isDefault || a.type.isInvestment || a.type.isLoan
            ? null
            : () => ref.read(accountProvider.notifier).setDefault(a.id),
        onDelete: a.isDefault ? null : () => _confirmDelete(context, ref, a),
      ).animate(delay: (40 * i).ms).fadeIn(duration: 300.ms);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Accounts',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _SummaryCard(portfolio: portfolio, symbol: symbol)
              .animate()
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          ...everyday.asMap().entries.map((e) => tile(e.value, e.key)),
          if (invest.isNotEmpty) ...[
            const _SectionLabel('Savings & investments'),
            ...invest
                .asMap()
                .entries
                .map((e) => tile(e.value, everyday.length + e.key)),
          ],
          if (loans.isNotEmpty) ...[
            const _SectionLabel('Loans & EMIs'),
            ...loans.asMap().entries.map(
                (e) => tile(e.value, everyday.length + invest.length + e.key)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSheet(context, null),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Account',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, AccountModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountFormSheet(existing: existing),
    );
  }

  void _showUpdateValue(
      BuildContext context, WidgetRef ref, AccountModel a, double invested) {
    showDialog(
      context: context,
      builder: (_) => _UpdateValueDialog(account: a, invested: invested),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AccountModel a) {
    final txCount = ref
        .read(transactionProvider)
        .where((t) => t.accountId == a.id || t.toAccountId == a.id)
        .length;
    final fallback = ref.read(accountRepoProvider).defaultAccount;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${a.name}"?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          txCount == 0
              ? 'This account has no transactions.'
              : '$txCount transaction${txCount == 1 ? '' : 's'} will move to "${fallback?.name ?? 'the default account'}". The opening balance of "${a.name}" is dropped.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(accountProvider.notifier).deleteAndReassign(a.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE8365D))),
          ),
        ],
      ),
    );
  }
}

/// Total balance, or Available / Invested / Net worth once there are
/// investment accounts.
class _SummaryCard extends StatelessWidget {
  final PortfolioSummary portfolio;
  final String symbol;

  const _SummaryCard({required this.portfolio, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final small = GoogleFonts.plusJakartaSans(
        fontSize: 13, color: onSurface.withValues(alpha: 0.6));
    final big = GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w800, color: onSurface);

    Widget figure(String label, double v, {String? extra, Color? extraColor}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: small.copyWith(fontSize: 12)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(AppFormatters.formatAmountCompact(v, symbol),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: v < 0 ? const Color(0xFFE8365D) : onSurface)),
              ),
              if (extra != null)
                Text(extra,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: extraColor)),
            ],
          ),
        );

    final ratio = portfolio.gainRatio;
    final up = portfolio.gain >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: portfolio.hasBreakdown
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net worth', style: small),
                const SizedBox(height: 4),
                Text(AppFormatters.formatAmount(portfolio.netWorth, symbol),
                    style: big),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    figure('Available to spend', portfolio.available),
                    if (portfolio.hasInvestments)
                      figure(
                        'Invested (today)',
                        portfolio.investedValue,
                        extra: ratio == null || portfolio.gain.abs() < 1
                            ? null
                            : '${up ? '+' : '−'}${AppFormatters.formatAmountCompact(portfolio.gain, symbol)} (${(ratio.abs() * 100).toStringAsFixed(1)}%)',
                        extraColor: up
                            ? (isDark
                                ? DarkColors.incomeGreen
                                : LightColors.incomeGreen)
                            : (isDark
                                ? DarkColors.expenseRed
                                : LightColors.expenseRed),
                      ),
                    if (portfolio.hasLoans)
                      figure('Loans owed', portfolio.loans),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total balance', style: small),
                const SizedBox(height: 4),
                Text(AppFormatters.formatAmount(portfolio.available, symbol),
                    style: big),
                const SizedBox(height: 4),
                Text(
                  'Opening balances plus everything you have logged since.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AccountModel account;

  /// Ledger balance; for investments this is the amount put in.
  final double invested;

  /// Worth today; equals [invested] for everyday accounts.
  final double value;
  final String symbol;
  final VoidCallback onTap;
  final VoidCallback? onUpdateValue;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  const _AccountTile({
    required this.account,
    required this.invested,
    required this.value,
    required this.symbol,
    required this.onTap,
    this.onUpdateValue,
    this.onSetDefault,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final negative = value < 0;
    final details = investmentDetails(account, invested, value, symbol);
    final gain = value - invested;
    final showGain = account.type.isInvestment && gain.abs() >= 1;
    final gainColor = gain >= 0
        ? (isDark ? DarkColors.incomeGreen : LightColors.incomeGreen)
        : (isDark ? DarkColors.expenseRed : LightColors.expenseRed);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: account.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(account.icon, color: account.color, size: 22),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                account.name,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (account.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: account.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Default',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: account.color,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          details ?? account.type.label,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: onSurface.withValues(alpha: 0.55)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  account.type.isInvestment || account.type.isLoan
                      ? AppFormatters.formatAmountCompact(value, symbol)
                      : AppFormatters.formatAmount(value, symbol),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: negative ? const Color(0xFFE8365D) : onSurface,
                  ),
                ),
                if (showGain)
                  Text(
                    '${gain >= 0 ? '+' : '−'}${AppFormatters.formatAmountCompact(gain, symbol)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: gainColor),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: onSurface.withValues(alpha: 0.5)),
              onSelected: (v) {
                if (v == 'edit') onTap();
                if (v == 'value') onUpdateValue?.call();
                if (v == 'default') onSetDefault?.call();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                if (onUpdateValue != null)
                  const PopupMenuItem(
                      value: 'value', child: Text('Update value')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (onSetDefault != null)
                  const PopupMenuItem(
                      value: 'default', child: Text('Set as default')),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: Color(0xFFE8365D))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One- or two-line description under an investment account's name, or null
/// for everyday accounts (which just show their type).
String? investmentDetails(
    AccountModel a, double invested, double value, String symbol,
    {DateTime? now}) {
  final today = now ?? DateTime.now();
  String money(double v) => AppFormatters.formatAmountCompact(v, symbol);
  String date(DateTime d) =>
      AppFormatters.formatDateShort(d) +
      (d.year == today.year ? '' : ' ${d.year}');

  switch (a.type) {
    case AccountType.fixedDeposit:
      final rate = a.interestRate;
      final maturity = a.maturityDate;
      if (rate == null || a.startDate == null) {
        return 'Fixed deposit · ${money(invested)} · edit to add rate and dates';
      }
      final parts = ['${_trim(rate)}% · ${money(invested)} deposited'];
      if (maturity != null) {
        if (maturity.isAfter(today)) {
          final payout = fdMaturityAmount(a, invested);
          parts.add('Matures ${date(maturity)}'
              '${payout == null ? '' : ' · ${money(payout)} then'}');
        } else {
          parts.add('Matured ${date(maturity)} · move it out with a transfer');
        }
      }
      return parts.join('\n');
    case AccountType.mutualFund || AccountType.stocks:
      final invLine = 'Invested ${money(invested)}';
      final updated = a.valueUpdatedAt;
      if (a.marketValue == null || updated == null) {
        return '$invLine\nTap ⋮ → Update value to add today\'s value';
      }
      final gain = value - invested;
      final pct = invested > 0
          ? ' (${gain >= 0 ? '+' : '−'}${(gain.abs() / invested * 100).toStringAsFixed(1)}%)'
          : '';
      return '$invLine$pct\nValue as of ${date(updated)}';
    case AccountType.chit:
      final p = chitProgress(a, today);
      if (invested < 0) {
        return 'Payout taken · ${money(-invested)} still to pay';
      }
      if (p == null) {
        return 'Chit · ${money(invested)} paid · edit to add amount and months';
      }
      final total = a.chitAmount;
      final perMonth =
          p.instalment == null ? '' : ' · ${money(p.instalment!)}/month';
      return 'Month ${p.month} of ${p.months}$perMonth\n'
          'Paid ${money(invested)}${total == null ? '' : ' of ${money(total)}'}';
    case AccountType.loan:
      final owed = -invested;
      if (owed <= 0.5) return 'Paid off';
      final rate = a.interestRate;
      final emi = a.emiAmount;
      final head = [
        rate == null
            ? 'Rate not set'
            : rate == 0
                ? 'No-cost EMI'
                : '${_trim(rate)}% a year',
        if (emi != null) 'EMI ${money(emi)}',
      ].join(' · ');
      final left = emisLeft(owed: owed, emi: emi, annualRatePercent: rate ?? 0);
      final String tail;
      if (emi == null) {
        tail = 'Edit to add the EMI amount';
      } else if (left == null) {
        tail = 'EMI does not cover the monthly interest';
      } else {
        final end = DateTime(today.year, today.month + left);
        tail = '$left EMI${left == 1 ? '' : 's'} left · ends ~'
            '${AppFormatters.formatMonthShort(end)}';
      }
      return '$head\n$tail';
    default:
      return null;
  }
}

String _trim(double v) =>
    v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toString();

String _amountText(double? v) => v == null || v == 0
    ? ''
    : v.abs().toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

double? _parseAmount(String text) {
  final t = text.trim().replaceAll(',', '');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

/// Mutual fund / stocks: type in today's total value from the fund or
/// broker app.
class _UpdateValueDialog extends ConsumerStatefulWidget {
  final AccountModel account;
  final double invested;
  const _UpdateValueDialog({required this.account, required this.invested});

  @override
  ConsumerState<_UpdateValueDialog> createState() => _UpdateValueDialogState();
}

class _UpdateValueDialogState extends ConsumerState<_UpdateValueDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final current = ref.read(accountValuesProvider)[widget.account.id];
    _ctrl = TextEditingController(text: _amountText(current));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = _parseAmount(_ctrl.text);
    if (v == null || v < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the current value as a number')),
      );
      return;
    }
    await ref.read(accountProvider.notifier).update(
        widget.account.withMarketValue(v, widget.invested, DateTime.now()));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.read(settingsProvider).currencySymbol;
    return AlertDialog(
      title: Text('Update ${widget.account.name}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invested so far: ${AppFormatters.formatAmount(widget.invested, symbol)}',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Current value',
              prefixText: '$symbol ',
              helperText: 'The "Current" figure in your app.',
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _AccountFormSheet extends ConsumerStatefulWidget {
  final AccountModel? existing;
  const _AccountFormSheet({this.existing});

  @override
  ConsumerState<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<_AccountFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _openingCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _chitAmountCtrl;
  late final TextEditingController _chitMonthsCtrl;
  late final TextEditingController _emiCtrl;
  late AccountType _type;
  late Color _color;
  DateTime? _startDate;
  DateTime? _maturityDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _openingCtrl = TextEditingController(text: _amountText(ex?.openingBalance));
    _rateCtrl = TextEditingController(
        text: ex?.interestRate == null ? '' : _trim(ex!.interestRate!));
    _valueCtrl = TextEditingController(
        text: ex == null || ex.marketValue == null
            ? ''
            : _amountText(ref.read(accountValuesProvider)[ex.id]));
    _chitAmountCtrl = TextEditingController(text: _amountText(ex?.chitAmount));
    _chitMonthsCtrl =
        TextEditingController(text: ex?.chitMonths?.toString() ?? '');
    _emiCtrl = TextEditingController(text: _amountText(ex?.emiAmount));
    _type = ex?.type ?? AccountType.bank;
    _color = ex?.color ?? _palette[0];
    _startDate = ex?.startDate;
    _maturityDate = ex?.maturityDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _openingCtrl.dispose();
    _rateCtrl.dispose();
    _valueCtrl.dispose();
    _chitAmountCtrl.dispose();
    _chitMonthsCtrl.dispose();
    _emiCtrl.dispose();
    super.dispose();
  }

  String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  void _error(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return _error('Please enter an account name');

    final openingText = _openingCtrl.text.trim();
    final opening = openingText.isEmpty ? 0.0 : _parseAmount(openingText);
    if (opening == null) return _error('Amount must be a number');

    final ex = widget.existing;
    if (ex != null && ex.isDefault && (_type.isInvestment || _type.isLoan)) {
      return _error(
          'The default account can\'t be an investment or loan. Set another account as default first.');
    }

    double? rate;
    DateTime? start, maturity;
    double? chitAmount;
    int? chitMonths;
    double? marketValue;
    double? emi;

    switch (_type) {
      case AccountType.loan:
        if (_rateCtrl.text.trim().isNotEmpty) {
          rate = _parseAmount(_rateCtrl.text);
          if (rate == null || rate < 0 || rate > 60) {
            return _error('Interest rate should be a percentage, e.g. 9.5');
          }
        }
        if (_emiCtrl.text.trim().isNotEmpty) {
          emi = _parseAmount(_emiCtrl.text);
          if (emi == null || emi <= 0) return _error('EMI must be a number');
        }
      case AccountType.fixedDeposit:
        if (_rateCtrl.text.trim().isNotEmpty) {
          rate = _parseAmount(_rateCtrl.text);
          if (rate == null || rate < 0 || rate > 30) {
            return _error('Interest rate should be a percentage, e.g. 7.1');
          }
        }
        start = _startDate;
        maturity = _maturityDate;
        if (start != null && maturity != null && !maturity.isAfter(start)) {
          return _error('Maturity date must be after the start date');
        }
      case AccountType.mutualFund || AccountType.stocks:
        if (_valueCtrl.text.trim().isNotEmpty) {
          marketValue = _parseAmount(_valueCtrl.text);
          if (marketValue == null || marketValue < 0) {
            return _error('Current value must be a number');
          }
        }
      case AccountType.chit:
        if (_chitAmountCtrl.text.trim().isNotEmpty) {
          chitAmount = _parseAmount(_chitAmountCtrl.text);
          if (chitAmount == null) return _error('Chit amount must be a number');
        }
        if (_chitMonthsCtrl.text.trim().isNotEmpty) {
          chitMonths = int.tryParse(_chitMonthsCtrl.text.trim());
          if (chitMonths == null || chitMonths <= 0 || chitMonths > 240) {
            return _error('Months should be a whole number, e.g. 20');
          }
        }
        start = _startDate;
      default:
        break;
    }

    setState(() => _saving = true);
    final signed = signedOpening(_type, opening);
    final notifier = ref.read(accountProvider.notifier);
    var account = AccountModel(
      id: ex?.id ?? const Uuid().v4(),
      name: name,
      type: _type,
      openingBalance: signed,
      colorHex: _hex(_color),
      sortOrder: ex?.sortOrder ?? ref.read(accountProvider).length,
      isDefault: ex?.isDefault ?? false,
      interestRate: rate,
      startDate: start,
      maturityDate: maturity,
      chitAmount: chitAmount,
      chitMonths: chitMonths,
      emiAmount: emi,
    );

    if (_type.hasMarketValue) {
      // What is invested once this save lands: the ledger balance with the
      // old opening balance swapped for the new one.
      final invested = ex == null
          ? signed
          : (ref.read(accountBalancesProvider)[ex.id] ?? ex.openingBalance) -
              ex.openingBalance +
              signed;
      final previous =
          ex == null ? null : ref.read(accountValuesProvider)[ex.id];
      final keepOld = ex != null &&
          ex.type == _type &&
          ex.marketValue != null &&
          marketValue != null &&
          previous != null &&
          (marketValue - previous).abs() < 0.005 &&
          ex.openingBalance == signed;
      if (keepOld) {
        account
          ..marketValue = ex.marketValue
          ..valuedInvested = ex.valuedInvested
          ..valueUpdatedAt = ex.valueUpdatedAt;
      } else if (marketValue != null) {
        account =
            account.withMarketValue(marketValue, invested, DateTime.now());
      }
    }

    if (ex != null) {
      await notifier.update(account);
    } else {
      await notifier.add(account);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate({required bool maturity}) async {
    final now = DateTime.now();
    final initial = (maturity ? _maturityDate : _startDate) ??
        (maturity ? DateTime(now.year + 1, now.month, now.day) : now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 30),
      helpText: maturity ? 'Maturity date' : 'Start date',
    );
    if (picked == null) return;
    setState(() {
      if (maturity) {
        _maturityDate = picked;
      } else {
        _startDate = picked;
      }
    });
  }

  ({String label, String helper, String hint}) get _openingText =>
      switch (_type) {
        AccountType.card => (
            label: 'Amount currently owed',
            helper: 'Entered as a negative balance.',
            hint: 'e.g. HDFC Millennia',
          ),
        AccountType.fixedDeposit => (
            label: 'Amount deposited',
            helper: 'The principal you put in.',
            hint: 'e.g. SBI FD 2025',
          ),
        AccountType.mutualFund => (
            label: 'Amount invested so far',
            helper:
                'Shown as "Invested" in your fund app. Future SIPs: add a monthly Transfer into this account.',
            hint: 'e.g. Groww SIPs',
          ),
        AccountType.stocks => (
            label: 'Amount invested so far',
            helper: 'Shown as "Invested" on your broker\'s portfolio screen.',
            hint: 'e.g. Zerodha',
          ),
        AccountType.chit => (
            label: 'Paid so far',
            helper:
                'Instalments paid until today. Log each new one as a Transfer into this account.',
            hint: 'e.g. Monthly kuri',
          ),
        AccountType.loan => (
            label: 'Amount still owed',
            helper:
                'Outstanding today, from your loan app or statement. Stored as a negative balance.',
            hint: 'e.g. Car loan, iPhone EMI',
          ),
        _ => (
            label: 'Opening balance',
            helper: 'What this account held when you started tracking.',
            hint: 'e.g. HDFC Savings, Wallet, Shyni cash',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final symbol = ref.read(settingsProvider).currencySymbol;
    final owedEntry = _type.isLiabilityEntry;
    final text = _openingText;
    final labelStyle = GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onSurface.withValues(alpha: 0.6));

    Widget chips(Iterable<AccountType> types) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((t) {
            final sel = t == _type;
            return ChoiceChip(
              selected: sel,
              avatar: Icon(t.icon, size: 16, color: sel ? _color : onSurface),
              label: Text(t.label),
              selectedColor: _color.withValues(alpha: 0.2),
              onSelected: (_) => setState(() => _type = t),
            );
          }).toList(),
        );

    Widget dateField(String label, DateTime? value, bool maturity) => Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickDate(maturity: maturity),
            icon: const Icon(Icons.event_rounded, size: 18),
            label: Text(
              value == null
                  ? label
                  : '$label\n${AppFormatters.formatDateShort(value)} ${value.year}',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            ),
          ),
        );

    final typeFields = <Widget>[
      if (_type == AccountType.loan) ...[
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _rateCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Interest % a year',
                hintText: '0 if no-cost',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _emiCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly EMI',
                hintText: '0',
                prefixText: '$symbol ',
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          'Pay each EMI as a Transfer from your bank (or card) into this '
          'account; turn on Repeat monthly to log it automatically. Trackify '
          'books the interest part as a "Loan Interest" expense and the rest '
          'lowers what you owe.',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
        ),
      ],
      if (_type == AccountType.fixedDeposit) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _rateCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Interest rate (% a year)',
            hintText: 'e.g. 7.1',
            prefixIcon: Icon(Icons.percent_rounded),
            helperText:
                'Value grows with quarterly compounding, like a cumulative FD.',
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          dateField('Start date', _startDate, false),
          const SizedBox(width: 10),
          dateField('Maturity date', _maturityDate, true),
        ]),
      ],
      if (_type.hasMarketValue) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _valueCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Current value (optional)',
            hintText: '0',
            prefixText: '$symbol ',
            helperText: 'Shown as "Current" in your app. Update it anytime.',
            prefixIcon: const Icon(Icons.trending_up_rounded),
          ),
        ),
      ],
      if (_type == AccountType.chit) ...[
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _chitAmountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Chit amount',
                hintText: '100000',
                prefixText: '$symbol ',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _chitMonthsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Months',
                hintText: '20',
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [dateField('First month', _startDate, false)]),
        const SizedBox(height: 6),
        Text(
          'When you get the payout, add a Transfer from this chit to your bank.',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
        ),
      ],
    ];

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1428) : const Color(0xFFF8FAFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing != null ? 'Edit Account' : 'New Account',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w800, color: onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: text.hint,
                prefixIcon: const Icon(Icons.badge_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('Type', style: labelStyle),
            const SizedBox(height: 8),
            chips(
                AccountType.values.where((t) => !t.isInvestment && !t.isLoan)),
            const SizedBox(height: 12),
            Text('Savings & investments', style: labelStyle),
            const SizedBox(height: 8),
            chips(AccountType.values.where((t) => t.isInvestment)),
            const SizedBox(height: 12),
            Text('Loans & EMIs', style: labelStyle),
            const SizedBox(height: 8),
            chips(AccountType.values.where((t) => t.isLoan)),
            const SizedBox(height: 16),
            TextField(
              controller: _openingCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: text.label,
                hintText: '0',
                prefixText: owedEntry ? '-$symbol ' : '$symbol ',
                helperText: text.helper,
                helperMaxLines: 3,
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
              ),
            ),
            ...typeFields,
            const SizedBox(height: 16),
            Text('Colour', style: labelStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _palette.map((c) {
                final sel = c.toARGB32() == _color.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? onSurface : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: sel
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(widget.existing != null ? 'Save' : 'Add Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Signed opening balance for cards and loans: the form shows "amount owed",
/// the model stores a negative number.
double signedOpening(AccountType type, double entered) =>
    type.isLiabilityEntry ? -entered.abs() : entered;
