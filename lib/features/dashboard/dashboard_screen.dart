import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_store.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/animated_counter.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../tips/tips_data.dart';
import '../transactions/add_transaction_screen.dart';
import '../accounts/manage_accounts_screen.dart';
import '../../data/models/account_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final void Function([TransactionType? initialType]) onAddTransaction;
  final VoidCallback onViewAllTransactions;

  const DashboardScreen({
    super.key,
    required this.onAddTransaction,
    required this.onViewAllTransactions,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final String _tipOfDay;

  @override
  void initState() {
    super.initState();
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    _tipOfDay = allTips[dayOfYear % allTips.length].text;
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoryProvider);
    final symbol = settings.currencySymbol;

    final catMap = {for (final c in categories) c.id: c};
    final txNotifier = ref.read(transactionProvider.notifier);
    final recent = transactions.take(5).toList();
    final monthlyIncome = txNotifier.thisMonthIncome;
    final monthlyExpense = txNotifier.thisMonthExpense;
    final accounts = ref.watch(accountProvider);
    final balances = ref.watch(accountBalancesProvider);
    final balance = ref.watch(totalBalanceProvider);
    final budgetRatio =
        settings.monthlyBudget != null && settings.monthlyBudget! > 0
            ? (monthlyExpense / settings.monthlyBudget!).clamp(0.0, 1.0)
            : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header section — greeting + balance card in a tinted container for light mode
          SliverToBoxAdapter(
            child: Container(
              decoration: isDark
                  ? null
                  : BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.13),
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.07),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppFormatters.formatGreeting()},',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                settings.userName.isNotEmpty
                                    ? '${settings.userName} 👋'
                                    : 'Welcome 👋',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (ImageStore.exists(settings.avatarPath))
                            CircleAvatar(
                              radius: 22,
                              backgroundImage:
                                  FileImage(File(settings.avatarPath!)),
                            )
                          else
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accent,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 22),
                            ),
                        ],
                      ),
                    ).animate(delay: 0.ms).fadeIn(duration: 400.ms).slideY(
                        begin: -0.3,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutExpo),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: _BalanceCard(
                        balance: balance,
                        income: monthlyIncome,
                        expense: monthlyExpense,
                        budgetRatio: budgetRatio,
                        currencySymbol: symbol,
                        monthlyBudget: settings.monthlyBudget,
                      ),
                    ).animate(delay: 60.ms).fadeIn(duration: 500.ms).scale(
                          begin: const Offset(0.92, 0.92),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.easeOutExpo,
                        ),
                    _AccountsRow(
                      accounts: accounts,
                      balances: balances,
                      currencySymbol: symbol,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageAccountsScreen(),
                        ),
                      ),
                    ).animate(delay: 120.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _QuickActions(
                onAddTransaction: widget.onAddTransaction,
                onOpenBudget: () => Navigator.of(context).pushNamed('/budget'),
                onScanSms: () => Navigator.of(context).pushNamed('/sms'),
              ),
            ).animate(delay: 240.ms).fadeIn(duration: 400.ms),
          ),

          // Mini bar chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: _MiniBarChart(
                  transactions:
                      ref.read(transactionRepoProvider).getLast7Days(),
                  currencySymbol: symbol,
                ),
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          ),

          // Recent transactions
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recent Transactions',
              actionLabel: 'See All',
              onAction: widget.onViewAllTransactions,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
          ),

          if (recent.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(onAdd: widget.onAddTransaction),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final tx = recent[i];
                  return TransactionTile(
                    transaction: tx,
                    category: catMap[tx.categoryId],
                    currencySymbol: symbol,
                    animationIndex: i,
                    onTap: () => _showDetail(context, tx),
                    onDelete: () => _deleteTransaction(tx.id),
                    onEdit: () => _editTransaction(tx),
                  );
                },
                childCount: recent.length,
              ),
            ),

          // Tip card
          SliverToBoxAdapter(
            child: Padding(
              // Clear the floating nav bar (Scaffold reports its height as
              // bottom padding because extendBody is on).
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.paddingOf(context).bottom + 24),
              child: _TipCard(
                tip: _tipOfDay,
                onTap: () => Navigator.of(context).pushNamed('/tips'),
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms).rotate(
                begin: 0.03,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutExpo),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, TransactionModel tx) {
    final cat = ref.read(categoryProvider.notifier).getById(tx.categoryId);
    final accRepo = ref.read(accountRepoProvider);
    final from =
        (tx.accountId == null ? null : accRepo.getById(tx.accountId!)) ??
            accRepo.defaultAccount;
    final to = tx.toAccountId == null ? null : accRepo.getById(tx.toAccountId!);
    final accountLabel = from == null
        ? null
        : to != null
            ? '${from.name} → ${to.name}'
            : from.name;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetail(
        transaction: tx,
        category: cat,
        accountLabel: accountLabel,
      ),
    );
  }

  Future<void> _deleteTransaction(String id) async {
    final notifier = ref.read(transactionProvider.notifier);
    final deleted = ref.read(transactionRepoProvider).getById(id);
    await notifier.delete(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        duration: const Duration(seconds: 5),
        action: deleted == null
            ? null
            : SnackBarAction(
                label: 'Undo',
                // Re-add a fresh copy; the original is detached from Hive.
                onPressed: () => notifier
                    .add(deleted.copyWith(updatedAt: deleted.updatedAt)),
              ),
      ),
    );
  }

  void _editTransaction(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => AddTransactionScreen(existingTransaction: tx),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final double budgetRatio;
  final String currencySymbol;
  final double? monthlyBudget;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.budgetRatio,
    required this.currencySymbol,
    this.monthlyBudget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                accent.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.05),
              ]
            : [
                accent.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.7),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: balance,
            prefix: currencySymbol,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This month',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _IncomeExpenseItem(
                  label: 'Income',
                  value: income,
                  color:
                      isDark ? DarkColors.incomeGreen : LightColors.incomeGreen,
                  icon: Icons.arrow_downward_rounded,
                  currencySymbol: currencySymbol,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _IncomeExpenseItem(
                  label: 'Expense',
                  value: expense,
                  color:
                      isDark ? DarkColors.expenseRed : LightColors.expenseRed,
                  icon: Icons.arrow_upward_rounded,
                  currencySymbol: currencySymbol,
                ),
              ),
              if (monthlyBudget != null && monthlyBudget! > 0) ...[
                const SizedBox(width: 16),
                _BudgetRing(ratio: budgetRatio, accent: accent),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Accounts Row ─────────────────────────────────────────────────────────────
class _AccountsRow extends StatelessWidget {
  final List<AccountModel> accounts;
  final Map<String, double> balances;
  final String currencySymbol;
  final VoidCallback onTap;

  const _AccountsRow({
    required this.accounts,
    required this.balances,
    required this.currencySymbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        physics: const BouncingScrollPhysics(),
        itemCount: accounts.length,
        itemBuilder: (ctx, i) {
          final a = accounts[i];
          final bal = balances[a.id] ?? a.openingBalance;
          return GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(a.icon, color: a.color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      Text(
                        AppFormatters.formatAmountCompact(bal, currencySymbol),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: bal < 0 ? const Color(0xFFE8365D) : onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IncomeExpenseItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String currencySymbol;

  const _IncomeExpenseItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          prefix: currencySymbol,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          decimalPlaces: 0,
        ),
      ],
    );
  }
}

class _BudgetRing extends StatelessWidget {
  final double ratio;
  final Color accent;

  const _BudgetRing({required this.ratio, required this.accent});

  @override
  Widget build(BuildContext context) {
    final color = ratio >= 0.85
        ? const Color(0xFFE8365D)
        : ratio >= 0.6
            ? const Color(0xFFFFB300)
            : const Color(0xFF00B87C);

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 5,
            strokeCap: StrokeCap.round,
          ),
          Text(
            '${(ratio * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final void Function([TransactionType? initialType]) onAddTransaction;
  final VoidCallback onOpenBudget;
  final VoidCallback onScanSms;

  const _QuickActions({
    required this.onAddTransaction,
    required this.onOpenBudget,
    required this.onScanSms,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.remove_circle_outline_rounded,
        label: 'Expense',
        color: const Color(0xFFE8365D),
        onTap: () => onAddTransaction(TransactionType.expense),
      ),
      (
        icon: Icons.add_circle_outline_rounded,
        label: 'Income',
        color: const Color(0xFF00B87C),
        onTap: () => onAddTransaction(TransactionType.income),
      ),
      (
        icon: Icons.savings_rounded,
        label: 'Budget',
        color: const Color(0xFFFFB300),
        onTap: onOpenBudget,
      ),
      (
        icon: Icons.sms_rounded,
        label: 'Scan SMS',
        color: const Color(0xFF6C63FF),
        onTap: onScanSms,
      ),
    ];

    return Row(
      children: List.generate(actions.length, (i) {
        final a = actions[i];
        return Expanded(
          child: GestureDetector(
            onTap: a.onTap,
            child: Container(
              margin: EdgeInsets.only(right: i < actions.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: a.color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(a.icon, color: a.color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    a.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: a.color,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 240 + i * 40)).scale(
              begin: const Offset(0, 0),
              duration: 400.ms,
              curve: Curves.elasticOut),
        );
      }),
    );
  }
}

// ─── Mini Bar Chart ───────────────────────────────────────────────────────────
class _MiniBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currencySymbol;

  const _MiniBarChart({
    required this.transactions,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    // Build daily data for last 7 days
    final now = DateTime.now();
    final dailyData = <int, double>{};
    for (int i = 6; i >= 0; i--) {
      dailyData[i] = 0;
    }
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final daysAgo = now.difference(tx.date).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          dailyData[daysAgo] = (dailyData[daysAgo] ?? 0) + tx.amount;
        }
      }
    }

    final maxVal = dailyData.values.fold(0.0, (m, v) => v > m ? v : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Day Spending',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal > 0 ? maxVal * 1.2 : 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final val = rod.toY;
                    return BarTooltipItem(
                      '$currencySymbol${val.toStringAsFixed(0)}',
                      GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final daysAgo = 6 - value.toInt();
                      final day = now.subtract(Duration(days: daysAgo));
                      return Text(
                        AppFormatters.formatDayShort(day),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                final daysAgo = 6 - i;
                final val = dailyData[daysAgo] ?? 0;
                final isToday = daysAgo == 0;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: val,
                      width: 18,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                      gradient: LinearGradient(
                        colors: isToday
                            ? [accent.withValues(alpha: 0.8), accent]
                            : [
                                accent.withValues(alpha: 0.3),
                                accent.withValues(alpha: 0.5),
                              ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tip Card ─────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final String tip;
  final VoidCallback? onTap;

  const _TipCard({required this.tip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: [
          const Color(0xFF6C63FF).withValues(alpha: 0.15),
          const Color(0xFF00D4FF).withValues(alpha: 0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Tip of the Day',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first transaction',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Transaction Detail Sheet ─────────────────────────────────────────────────
class _TransactionDetail extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final String? accountLabel;

  const _TransactionDetail({
    required this.transaction,
    required this.category,
    this.accountLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome
        ? (isDark ? DarkColors.incomeGreen : LightColors.incomeGreen)
        : transaction.type == TransactionType.transfer
            ? (isDark ? DarkColors.transferColor : LightColors.transferColor)
            : (isDark ? DarkColors.expenseRed : LightColors.expenseRed);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1428) : const Color(0xFFF8FAFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (category != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: category!.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(category!.icon, color: category!.color, size: 30),
              ),
            const SizedBox(height: 12),
            Text(
              '${isIncome ? '+' : transaction.type == TransactionType.transfer ? '↔ ' : '-'}${AppFormatters.formatAmount(transaction.amount, '')}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.formatDateTime(transaction.date),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            if (accountLabel != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      size: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text(
                    accountLabel!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
            if (transaction.note.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                transaction.note,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (ImageStore.exists(transaction.receiptImagePath)) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(transaction.receiptImagePath!),
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
