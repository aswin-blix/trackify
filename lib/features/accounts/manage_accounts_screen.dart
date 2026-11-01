import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/formatters.dart';
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
class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);
    final balances = ref.watch(accountBalancesProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final total = balances.values.fold(0.0, (s, v) => s + v);
    final onSurface = Theme.of(context).colorScheme.onSurface;

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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total balance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatAmount(total, symbol),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
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
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          ...accounts.asMap().entries.map((e) {
            final a = e.value;
            return _AccountTile(
              account: a,
              balance: balances[a.id] ?? a.openingBalance,
              symbol: symbol,
              onTap: () => _showSheet(context, a),
              onSetDefault: a.isDefault
                  ? null
                  : () => ref.read(accountProvider.notifier).setDefault(a.id),
              onDelete:
                  a.isDefault ? null : () => _confirmDelete(context, ref, a),
            ).animate(delay: (40 * e.key).ms).fadeIn(duration: 300.ms);
          }),
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

class _AccountTile extends StatelessWidget {
  final AccountModel account;
  final double balance;
  final String symbol;
  final VoidCallback onTap;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  const _AccountTile({
    required this.account,
    required this.balance,
    required this.symbol,
    required this.onTap,
    this.onSetDefault,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final negative = balance < 0;
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
          account.type.label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppFormatters.formatAmount(balance, symbol),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: negative ? const Color(0xFFE8365D) : onSurface,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: onSurface.withValues(alpha: 0.5)),
              onSelected: (v) {
                if (v == 'edit') onTap();
                if (v == 'default') onSetDefault?.call();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
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

class _AccountFormSheet extends ConsumerStatefulWidget {
  final AccountModel? existing;
  const _AccountFormSheet({this.existing});

  @override
  ConsumerState<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<_AccountFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _openingCtrl;
  late AccountType _type;
  late Color _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _openingCtrl = TextEditingController(
      text: ex == null || ex.openingBalance == 0
          ? ''
          : ex.openingBalance.abs().toStringAsFixed(
              ex.openingBalance.truncateToDouble() == ex.openingBalance
                  ? 0
                  : 2),
    );
    _type = ex?.type ?? AccountType.bank;
    _color = ex?.color ?? _palette[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _openingCtrl.dispose();
    super.dispose();
  }

  String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an account name')),
      );
      return;
    }
    final openingText = _openingCtrl.text.trim().replaceAll(',', '');
    final opening = openingText.isEmpty ? 0.0 : double.tryParse(openingText);
    if (opening == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening balance must be a number')),
      );
      return;
    }
    setState(() => _saving = true);
    final ex = widget.existing;
    final notifier = ref.read(accountProvider.notifier);
    if (ex != null) {
      await notifier.update(ex.copyWith(
        name: name,
        type: _type,
        openingBalance: signedOpening(_type, opening),
        colorHex: _hex(_color),
      ));
    } else {
      final count = ref.read(accountProvider).length;
      await notifier.add(AccountModel(
        id: const Uuid().v4(),
        name: name,
        type: _type,
        openingBalance: signedOpening(_type, opening),
        colorHex: _hex(_color),
        sortOrder: count,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final symbol = ref.read(settingsProvider).currencySymbol;
    final isCard = _type == AccountType.card;

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
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. HDFC Savings, Wallet, Shyni cash',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('Type',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AccountType.values.map((t) {
                final sel = t == _type;
                return ChoiceChip(
                  selected: sel,
                  avatar:
                      Icon(t.icon, size: 16, color: sel ? _color : onSurface),
                  label: Text(t.label),
                  selectedColor: _color.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _openingCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: isCard ? 'Amount currently owed' : 'Opening balance',
                hintText: '0',
                prefixText: isCard ? '-$symbol ' : '$symbol ',
                helperText: isCard
                    ? 'Entered as a negative balance.'
                    : 'What this account held when you started tracking.',
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('Colour',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.6))),
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

/// Signed opening balance for credit cards: the form shows "amount owed",
/// the model stores a negative number.
double signedOpening(AccountType type, double entered) =>
    type == AccountType.card ? -entered.abs() : entered;
