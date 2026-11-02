import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/debt_ledger.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/providers/app_providers.dart';
import '../household/household_service.dart';
import 'debt_entry_sheet.dart';
import 'debt_providers.dart';

/// First name of a household member, "You" for the current user.
String debtOwnerName(WidgetRef ref, String owner) {
  if (owner == ref.watch(myDebtOwnerProvider)) return 'You';
  final name = ref.watch(householdMembersProvider)[owner];
  return name == null || name.trim().isEmpty
      ? 'Partner'
      : name.trim().split(' ').first;
}

/// Everyone you (and your partner) lent to or borrowed from.
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myDebtOwnerProvider);
    final members = ref.watch(householdMembersProvider);
    final shared = members.length > 1;
    final filter = shared ? ref.watch(debtOwnerFilterProvider) : me;
    final all = ref.watch(allDebtBalancesProvider);
    final list =
        filter == null ? all : all.where((p) => p.owner == filter).toList();
    final open = list.where((p) => !p.isSettled).toList();
    final settled = list.where((p) => p.isSettled).toList();
    final totals = DebtLedger.totals(list);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final who = filter == null
        ? 'you both'
        : filter == me
            ? 'you'
            : debtOwnerName(ref, filter);
    final whoCap = who == 'you'
        ? 'You'
        : who == 'you both'
            ? 'You both'
            : who;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Lent & Borrowed',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (shared) ...[
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Everyone'),
                  selected: filter == null,
                  onSelected: (_) =>
                      ref.read(debtOwnerFilterProvider.notifier).state = null,
                ),
                for (final uid in [
                  me,
                  ...members.keys.where((k) => k != me),
                ])
                  ChoiceChip(
                    label: Text(debtOwnerName(ref, uid)),
                    selected: filter == uid,
                    onSelected: (_) =>
                        ref.read(debtOwnerFilterProvider.notifier).state = uid,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _SummaryCard(
            owedLabel: 'Owed to $who',
            oweLabel:
                '$whoCap owe${whoCap == 'You' || whoCap == 'You both' ? '' : 's'}',
            owed: totals.owedToYou,
            owe: totals.youOwe,
            symbol: symbol,
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          if (list.isEmpty)
            _Empty(onAdd: () => showDebtEntrySheet(context))
          else ...[
            for (final (i, p) in open.indexed)
              _PersonTile(balance: p, showOwner: shared && filter == null)
                  .animate(delay: (30 * i).ms)
                  .fadeIn(duration: 250.ms),
            if (settled.isNotEmpty)
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    'Settled (${settled.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  children: [
                    for (final p in settled)
                      _PersonTile(
                          balance: p, showOwner: shared && filter == null),
                  ],
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDebtEntrySheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('New entry',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String owedLabel;
  final String oweLabel;
  final double owed;
  final double owe;
  final String symbol;

  const _SummaryCard({
    required this.owedLabel,
    required this.oweLabel,
    required this.owed,
    required this.owe,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    Widget cell(String label, double v, Color c, IconData icon) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 16, color: c),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.6))),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                AppFormatters.formatAmount(v, symbol),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: v > 0 ? c : onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        cell(
            owedLabel,
            owed,
            isDark ? DarkColors.incomeGreen : LightColors.incomeGreen,
            Icons.call_made_rounded),
        const SizedBox(width: 12),
        cell(
            oweLabel,
            owe,
            isDark ? DarkColors.expenseRed : LightColors.expenseRed,
            Icons.call_received_rounded),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;
  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.handshake_outlined,
              size: 56, color: onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('Nothing lent or borrowed',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: onSurface)),
          const SizedBox(height: 8),
          Text(
            'Record money you lend or borrow and Trackify keeps a running '
            'balance per person, with a reminder on the due date.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends ConsumerWidget {
  final PersonBalance balance;
  final bool showOwner;
  const _PersonTile({required this.balance, required this.showOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final p = balance;
    final green = isDark ? DarkColors.incomeGreen : LightColors.incomeGreen;
    final red = isDark ? DarkColors.expenseRed : LightColors.expenseRed;
    final color = p.isSettled
        ? onSurface.withValues(alpha: 0.45)
        : p.theyOwe
            ? green
            : red;
    final owner = debtOwnerName(ref, p.owner);
    final ownerIsMe = owner == 'You';

    final status = p.isSettled
        ? 'Settled'
        : p.theyOwe
            ? 'Owes ${ownerIsMe ? 'you' : owner}'
            : ownerIsMe
                ? 'You owe'
                : '$owner owes';
    final overdue = p.isOverdue(DateTime.now());
    final due = p.dueDate == null || p.isSettled
        ? ''
        : overdue
            ? ' · overdue since ${DateFormat('d MMM').format(p.dueDate!)}'
            : ' · due ${DateFormat('d MMM').format(p.dueDate!)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: overdue ? Border.all(color: red.withValues(alpha: 0.5)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PersonDebtScreen(
              owner: p.owner, personKey: DebtLedger.personKey(p.name)),
        )),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Text(p.name.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        title: Row(children: [
          Flexible(
            child: Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: onSurface)),
          ),
          if (showOwner && !ownerIsMe) ...[
            const SizedBox(width: 6),
            _OwnerBadge(owner),
          ],
        ]),
        subtitle: Text(
          '$status$due',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: overdue ? red : onSurface.withValues(alpha: 0.55),
            fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: Text(
          AppFormatters.formatAmount(p.net.abs(), symbol),
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, fontSize: 15, color: color),
        ),
      ),
    );
  }
}

class _OwnerBadge extends StatelessWidget {
  final String name;
  const _OwnerBadge(this.name);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(name,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w700, color: primary)),
    );
  }
}

/// Full history with one person, with a running balance and quick actions.
class PersonDebtScreen extends ConsumerWidget {
  final String owner;
  final String personKey;

  const PersonDebtScreen(
      {super.key, required this.owner, required this.personKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(allDebtBalancesProvider).where(
        (b) => b.owner == owner && DebtLedger.personKey(b.name) == personKey);
    if (p.isEmpty) {
      // Everything for this person was deleted.
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No entries left')),
      );
    }
    final b = p.first;
    final isMine = owner == ref.watch(myDebtOwnerProvider);
    final ownerName = debtOwnerName(ref, owner);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final green = isDark ? DarkColors.incomeGreen : LightColors.incomeGreen;
    final red = isDark ? DarkColors.expenseRed : LightColors.expenseRed;
    final color = b.isSettled
        ? onSurface.withValues(alpha: 0.6)
        : b.theyOwe
            ? green
            : red;
    final headline = b.isSettled
        ? 'All settled'
        : b.theyOwe
            ? '${b.name} owes ${isMine ? 'you' : ownerName}'
            : '${isMine ? 'You owe' : '$ownerName owes'} ${b.name}';

    // Running balance after each entry, newest first for display.
    var running = 0.0;
    final rows = <(TransactionModel, double)>[];
    for (final t in b.entries) {
      running += DebtLedger.effect(t);
      rows.add((t, running));
    }
    final display = rows.reversed.toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(b.name,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatAmount(b.net.abs(), symbol),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 30, fontWeight: FontWeight.w800, color: color),
                ),
                if (b.dueDate != null && !b.isSettled) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${b.isOverdue(DateTime.now()) ? 'Overdue since' : 'Due'} '
                    '${DateFormat('d MMM yyyy').format(b.dueDate!)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: b.isOverdue(DateTime.now())
                          ? red
                          : onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                if (!isMine) ...[
                  const SizedBox(height: 6),
                  Text("$ownerName's entries. Only they can add to them.",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: onSurface.withValues(alpha: 0.5))),
                ],
              ],
            ),
          ),
          if (isMine) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (!b.isSettled)
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: Text(b.theyOwe ? 'Got paid back' : 'Paid back'),
                      onPressed: () => showDebtEntrySheet(
                        context,
                        type: b.theyOwe
                            ? TransactionType.collect
                            : TransactionType.repay,
                        person: b.name,
                        amount: b.net.abs(),
                      ),
                    ),
                  ),
                if (!b.isSettled) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(b.youOwe ? 'Borrow more' : 'Lend more'),
                    onPressed: () => showDebtEntrySheet(
                      context,
                      type: b.youOwe
                          ? TransactionType.borrow
                          : TransactionType.lend,
                      person: b.name,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('History',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          for (final (t, after) in display)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              onTap: isMine
                  ? () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DebtEntrySheet(existing: t),
                      )
                  : null,
              title: Text(
                DebtLedger.describe(t),
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: onSurface),
              ),
              subtitle: Text(
                [
                  DateFormat('d MMM yyyy').format(t.date),
                  if (t.note.isNotEmpty) t.note,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: onSurface.withValues(alpha: 0.55)),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${DebtLedger.effect(t) > 0 ? '+' : '−'}'
                    '${AppFormatters.formatAmount(t.amount, symbol)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: DebtLedger.effect(t) > 0 ? green : red),
                  ),
                  Text(
                    after.abs() < 0.005
                        ? 'settled'
                        : 'balance ${AppFormatters.formatAmount(after.abs(), symbol)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
