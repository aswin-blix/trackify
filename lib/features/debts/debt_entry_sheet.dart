import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/account_picker.dart';
import '../transactions/add_transaction_screen.dart';
import 'debt_providers.dart';

/// The right editor for [tx]: the loan sheet for lend/borrow/collect/repay,
/// the normal add sheet for everything else.
Widget transactionEditorFor(TransactionModel tx) => tx.type.isDebt
    ? DebtEntrySheet(existing: tx)
    : AddTransactionScreen(existingTransaction: tx);

Future<void> showDebtEntrySheet(
  BuildContext context, {
  TransactionType type = TransactionType.lend,
  String? person,
  double? amount,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => DebtEntrySheet(
      initialType: type,
      initialPerson: person,
      initialAmount: amount,
    ),
  );
}

/// Records money lent, borrowed, or paid back.
class DebtEntrySheet extends ConsumerStatefulWidget {
  final TransactionModel? existing;
  final TransactionType initialType;
  final String? initialPerson;
  final double? initialAmount;

  const DebtEntrySheet({
    super.key,
    this.existing,
    this.initialType = TransactionType.lend,
    this.initialPerson,
    this.initialAmount,
  });

  @override
  ConsumerState<DebtEntrySheet> createState() => _DebtEntrySheetState();
}

class _DebtEntrySheetState extends ConsumerState<DebtEntrySheet> {
  late TransactionType _type;
  late final TextEditingController _person;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  String? _accountId;
  late DateTime _date;
  DateTime? _due;
  bool _saving = false;

  static const _types = [
    (TransactionType.lend, 'Lent', Icons.call_made_rounded),
    (TransactionType.borrow, 'Borrowed', Icons.call_received_rounded),
    (TransactionType.collect, 'Got back', Icons.south_west_rounded),
    (TransactionType.repay, 'Paid back', Icons.north_east_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _type = ex?.type ?? widget.initialType;
    _person =
        TextEditingController(text: ex?.counterparty ?? widget.initialPerson);
    final amt = ex?.amount ?? widget.initialAmount;
    _amount = TextEditingController(
        text: amt == null
            ? ''
            : amt == amt.roundToDouble()
                ? amt.toStringAsFixed(0)
                : amt.toStringAsFixed(2));
    _note = TextEditingController(text: ex?.note ?? '');
    _accountId = ex?.accountId;
    _date = ex?.date ?? DateTime.now();
    _due = ex?.dueDate;
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _isLoan =>
      _type == TransactionType.lend || _type == TransactionType.borrow;

  String get _personLabel => switch (_type) {
        TransactionType.lend => 'Lent to',
        TransactionType.borrow => 'Borrowed from',
        TransactionType.collect => 'Paid back by',
        _ => 'Paid back to',
      };

  String get _accountLabel => _type.isInflow ? 'Into account' : 'From account';

  Future<void> _save() async {
    final person = _person.text.trim();
    final amount = double.tryParse(_amount.text.trim());
    if (person.isEmpty) return _error('Enter who it was with');
    if (amount == null || amount <= 0) return _error('Enter a valid amount');

    setState(() => _saving = true);
    final ex = widget.existing;
    final now = DateTime.now();
    final tx = TransactionModel(
      id: ex?.id ?? const Uuid().v4(),
      amount: amount,
      type: _type,
      categoryId: kDebtCategoryId,
      note: _note.text.trim(),
      tags: ex?.tags,
      date: _date,
      createdAt: ex?.createdAt ?? now,
      updatedAt: now,
      addedBy: ex?.addedBy,
      accountId: _accountId ?? ref.read(accountRepoProvider).defaultAccount?.id,
      counterparty: person,
      dueDate: _isLoan ? _due : null,
    );
    try {
      final n = ref.read(transactionProvider.notifier);
      ex == null ? await n.add(tx) : await n.update(tx);
      await ref.read(debtReminderSyncProvider)();
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, stack) {
      AppLogger.e('DebtEntrySheet', 'Save failed', e, stack);
      if (mounted) setState(() => _saving = false);
      _error('Could not save. Please try again.');
    }
  }

  Future<void> _delete() async {
    final ex = widget.existing;
    if (ex == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text(DebtLedgerText.of(ex)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(transactionProvider.notifier).delete(ex.id);
    await ref.read(debtReminderSyncProvider)();
    if (mounted) Navigator.of(context).pop(true);
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFFE8365D),
    ));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() =>
          _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
    }
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (d != null) setState(() => _due = d);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final color = isDark ? DarkColors.debtColor : LightColors.debtColor;
    final accounts = ref.watch(accountProvider);
    final defaultId = accounts.where((a) => a.isDefault).firstOrNull?.id ??
        accounts.firstOrNull?.id;
    final people = ref.watch(knownDebtPeopleProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final fmt = DateFormat('d MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1428) : const Color(0xFFF8FAFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.existing == null
                            ? 'Lent & Borrowed'
                            : 'Edit entry',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                    ),
                    if (widget.existing != null)
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: _delete,
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (t, label, icon) in _types)
                      ChoiceChip(
                        avatar: Icon(icon,
                            size: 16,
                            color: t == _type
                                ? color
                                : onSurface.withValues(alpha: 0.6)),
                        label: Text(label),
                        selected: t == _type,
                        onSelected: (_) => setState(() => _type = t),
                        selectedColor: color.withValues(alpha: 0.16),
                        showCheckmark: false,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight:
                              t == _type ? FontWeight.w700 : FontWeight.w500,
                          color: t == _type
                              ? color
                              : onSurface.withValues(alpha: 0.8),
                        ),
                        side: BorderSide(
                          color: t == _type
                              ? color
                              : onSurface.withValues(alpha: 0.15),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _person,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: _personLabel,
                    hintText: 'Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
              ),
              // Recent people, filtered by what's typed.
              Builder(builder: (context) {
                final q = _person.text.trim().toLowerCase();
                final matches = people
                    .where((p) =>
                        p.toLowerCase() != q &&
                        (q.isEmpty || p.toLowerCase().contains(q)))
                    .take(8)
                    .toList();
                if (matches.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    children: [
                      for (final p in matches)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(p),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() {
                              _person.text = p;
                              _person.selection =
                                  TextSelection.collapsed(offset: p.length);
                            }),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '$symbol ',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AccountPicker(
                label: _accountLabel,
                accounts: accounts,
                selectedId: _accountId ?? defaultId,
                onSelect: (id) => setState(() => _accountId = id),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: fmt.format(_date),
                        onTap: _pickDate,
                      ),
                    ),
                    if (_isLoan) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          icon: Icons.event_available_rounded,
                          label: 'Due (optional)',
                          value: _due == null ? 'None' : fmt.format(_due!),
                          onTap: _pickDue,
                          onClear: _due == null
                              ? null
                              : () => setState(() => _due = null),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _note,
                  decoration: const InputDecoration(
                    hintText: 'Note (optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Changes the account balance, but never counts as income '
                  'or expense.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            widget.existing == null ? 'Save' : 'Update',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Readable one-liner for dialogs.
class DebtLedgerText {
  static String of(TransactionModel t) {
    final who = t.counterparty ?? 'someone';
    return switch (t.type) {
      TransactionType.lend => 'Lent ${t.amount} to $who',
      TransactionType.borrow => 'Borrowed ${t.amount} from $who',
      TransactionType.collect => '$who paid back ${t.amount}',
      _ => 'Paid back ${t.amount} to $who',
    };
  }
}

class _DateField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: onSurface.withValues(alpha: 0.55))),
                  Text(value,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: onSurface)),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}
