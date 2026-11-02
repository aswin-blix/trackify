import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/recurrence.dart';
import '../../data/models/recurring_model.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/providers/app_providers.dart';
import '../transactions/add_transaction_screen.dart';

/// Lists recurring rules: pause/resume, change amount, delete, add new.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // Monthly-equivalent outflow of active expense rules, as a quick total.
    final monthly = rules
        .where((r) =>
            r.active && !r.isFinished && r.type == TransactionType.expense)
        .fold(0.0, (s, r) => s + _monthlyEquivalent(r));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Recurring',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: rules.isEmpty
          ? _EmptyState(onAdd: () => _openAdd(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring expenses per month',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.formatAmount(monthly, symbol),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Entries are added on their due date each time you '
                        'open Trackify.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 16),
                ...rules.asMap().entries.map((e) => _RuleTile(rule: e.value)
                    .animate(delay: (40 * e.key).ms)
                    .fadeIn(duration: 300.ms)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Recurring',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static double _monthlyEquivalent(RecurringModel r) {
    final n = r.interval < 1 ? 1 : r.interval;
    return switch (r.frequency) {
      RecurrenceFrequency.daily => r.amount * 30.44 / n,
      RecurrenceFrequency.weekly => r.amount * 4.345 / n,
      RecurrenceFrequency.monthly => r.amount / n,
      RecurrenceFrequency.yearly => r.amount / (12 * n),
    };
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const AddTransactionScreen(
        initialRepeat: RecurrenceFrequency.monthly,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_repeat_rounded,
                size: 56, color: onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              'No recurring transactions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rent, salary, subscriptions, EMIs: set them once and Trackify '
              'adds them on schedule. You can also pick Repeat when adding '
              'any transaction.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleTile extends ConsumerWidget {
  final RecurringModel rule;
  const _RuleTile({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final cat = ref.read(categoryProvider.notifier).getById(rule.categoryId);
    final title = rule.note.isNotEmpty ? rule.note : (cat?.name ?? 'Recurring');
    final color = switch (rule.type) {
      TransactionType.expense =>
        isDark ? DarkColors.expenseRed : LightColors.expenseRed,
      TransactionType.income =>
        isDark ? DarkColors.incomeGreen : LightColors.incomeGreen,
      TransactionType.transfer =>
        isDark ? DarkColors.transferColor : LightColors.transferColor,
    };
    final sign = switch (rule.type) {
      TransactionType.expense => '-',
      TransactionType.income => '+',
      TransactionType.transfer => '',
    };
    final status = !rule.active
        ? 'Paused'
        : rule.isFinished
            ? 'Ended'
            : 'Next ${DateFormat('d MMM yyyy').format(rule.nextDate)}';

    return Opacity(
      opacity: rule.active && !rule.isFinished ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          onTap: () => _showActions(context, ref),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (cat?.color ?? color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat?.icon ?? Icons.repeat_rounded,
                color: cat?.color ?? color, size: 20),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: onSurface,
            ),
          ),
          subtitle: Text(
            '${rule.frequency.describe(rule.interval)} · $status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.55),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$sign${AppFormatters.formatAmount(rule.amount, symbol)}',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: color,
                ),
              ),
              Switch(
                value: rule.active,
                onChanged: rule.isFinished
                    ? null
                    : (v) => ref
                        .read(recurringProvider.notifier)
                        .setActive(rule.id, v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Change amount'),
              subtitle: const Text('Applies to future entries only'),
              onTap: () {
                Navigator.pop(ctx);
                _editAmount(context, ref);
              },
            ),
            ListTile(
              leading: Icon(rule.active
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded),
              title: Text(rule.active ? 'Pause' : 'Resume'),
              subtitle: rule.active
                  ? null
                  : const Text('Missed dates are skipped, not back-filled'),
              enabled: !rule.isFinished,
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(recurringProvider.notifier)
                    .setActive(rule.id, !rule.active);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFE8365D)),
              title: const Text('Delete',
                  style: TextStyle(color: Color(0xFFE8365D))),
              subtitle: const Text('Entries already added are kept'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAmount(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: rule.amount.toString());
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change amount',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              Navigator.pop(ctx, v != null && v > 0 ? v : null);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    rule.amount = value;
    await ref.read(recurringProvider.notifier).update(rule);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete this repeat?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: const Text(
            'No more entries will be added. Ones already added stay in your '
            'transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(recurringProvider.notifier).delete(rule.id);
    }
  }
}
