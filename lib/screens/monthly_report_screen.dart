import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/expense_provider.dart';
import '../utils/icon_helpers.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _viewMonth = DateTime.now();

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _viewMonth.year == now.year && _viewMonth.month == now.month;
  }

  void _previousMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
  }

  void _nextMonth() {
    if (!_isCurrentMonth) {
      setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (ctx, anim1, anim2) => const DashboardScreen(),
                transitionDuration: Duration.zero,
              ),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: _previousMonth,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Text(
              '${_monthNames[_viewMonth.month]} ${_viewMonth.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                size: 20,
                color: _isCurrentMonth ? Colors.grey.withValues(alpha: 0.4) : null,
              ),
              onPressed: _isCurrentMonth ? null : _nextMonth,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Expenses'),
            Tab(text: 'Savings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildExpensesTab(),
          _buildSavingsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ──────────────────────── OVERVIEW TAB ────────────────────────

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildDonutChartSection(),
          const SizedBox(height: 16),
          _buildInsightsList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final currentExp = provider.getMonthlyTotal(_viewMonth.year, _viewMonth.month, isExpense: true);
        final lastMonthDate = DateTime(_viewMonth.year, _viewMonth.month - 1);
        final lastExp = provider.getMonthlyTotal(lastMonthDate.year, lastMonthDate.month, isExpense: true);

        double percentChange = 0;
        bool increased = false;
        if (lastExp > 0) {
          percentChange = ((currentExp - lastExp) / lastExp * 100).abs();
          increased = currentExp > lastExp;
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
          ),
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey.withValues(alpha: 0.05)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL EXPENSES',
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('\$${currentExp.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (lastExp > 0)
                    Row(
                      children: [
                        Icon(
                          increased ? Icons.trending_up : Icons.trending_down,
                          color: increased ? const Color(0xFFff6b6b) : const Color(0xFF39ff14),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${percentChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: increased ? const Color(0xFFff6b6b) : const Color(0xFF39ff14),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('vs last month', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    )
                  else
                    const Text('No data for last month', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonutChartSection() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final groupedData = provider.getExpensesByCategory(_viewMonth.year, _viewMonth.month);
        final totalExp = provider.getMonthlyTotal(_viewMonth.year, _viewMonth.month, isExpense: true);

        if (groupedData.isEmpty || totalExp == 0) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: const Center(child: Text("No expenses to chart yet.")),
          );
        }

        List<PieChartSectionData> sections = [];
        List<Widget> legends = [];
        int maxCatId = -1;
        double maxCatAmount = -1;

        groupedData.forEach((catId, amount) {
          final cat = provider.getCategoryById(catId);
          if (cat != null) {
            if (amount > maxCatAmount) {
              maxCatAmount = amount;
              maxCatId = catId;
            }
            final color = IconHelpers.parseColor(cat.colorCode);
            final percentage = (amount / totalExp) * 100;
            sections.add(PieChartSectionData(color: color, value: amount, title: '', radius: 40));
            legends.add(_buildLegendItem(color, cat.name, percentage));
          }
        });

        final topCat = provider.getCategoryById(maxCatId);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Expenses by Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 60, sections: sections)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('TOP SPEND',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(
                            topCat?.name ?? '',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          Text('\$${maxCatAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 5,
                children: legends,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String name, double percentage) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$name (${percentage.toStringAsFixed(0)}%)',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildInsightsList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final insights = _generateInsights(provider);
        if (insights.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInsightItem(
                icon: insight['icon'] as IconData,
                iconColor: insight['color'] as Color,
                title: insight['title'] as String,
                subtitle: insight['subtitle'] as String,
                bgColor: (insight['color'] as Color).withValues(alpha: 0.1),
              ),
            )),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _generateInsights(ExpenseProvider provider) {
    final insights = <Map<String, dynamic>>[];
    final lastMonthDate = DateTime(_viewMonth.year, _viewMonth.month - 1);

    final currentExp = provider.getMonthlyTotal(_viewMonth.year, _viewMonth.month, isExpense: true);
    final lastExp = provider.getMonthlyTotal(lastMonthDate.year, lastMonthDate.month, isExpense: true);
    final currentIncome = provider.getMonthlyTotal(_viewMonth.year, _viewMonth.month, isExpense: false);

    if (lastExp > 0 && currentExp > lastExp * 1.1) {
      final pct = ((currentExp - lastExp) / lastExp * 100).toStringAsFixed(0);
      insights.add({
        'icon': Icons.warning,
        'color': const Color(0xFFff7f50),
        'title': 'Spending Alert',
        'subtitle': 'Your spending is $pct% higher than last month. Consider reviewing your expenses.',
      });
    }

    final savings = currentIncome - currentExp;
    if (currentIncome > 0 && savings > 0) {
      final rate = (savings / currentIncome * 100).toStringAsFixed(0);
      insights.add({
        'icon': Icons.auto_awesome,
        'color': const Color(0xFF39ff14),
        'title': 'Great Savings!',
        'subtitle': "You're saving $rate% of your income this month. Keep it up!",
      });
    } else if (currentIncome > 0 && savings < 0) {
      insights.add({
        'icon': Icons.info_outline,
        'color': const Color(0xFF135bec),
        'title': 'Budget Tip',
        'subtitle': 'Your expenses exceed your income this month. Review where you can cut back.',
      });
    }

    final grouped = provider.getExpensesByCategory(_viewMonth.year, _viewMonth.month);
    if (grouped.isNotEmpty && currentExp > 0) {
      final topEntry = grouped.entries.reduce((a, b) => a.value > b.value ? a : b);
      final pct = (topEntry.value / currentExp * 100);
      if (pct > 50) {
        final cat = provider.getCategoryById(topEntry.key);
        if (cat != null) {
          insights.add({
            'icon': Icons.pie_chart,
            'color': const Color(0xFFa855f7),
            'title': 'Category Focus',
            'subtitle': '${cat.name} is ${pct.toStringAsFixed(0)}% of your expenses. Diversifying may help.',
          });
        }
      }
    }

    return insights;
  }

  Widget _buildInsightItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── EXPENSES TAB ────────────────────────

  Widget _buildExpensesTab() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final expenses = provider.transactions
            .where((t) =>
                t.isExpense &&
                t.date.year == _viewMonth.year &&
                t.date.month == _viewMonth.month)
            .toList();

        if (expenses.isEmpty) {
          return const Center(
            child: Text('No expenses for this month.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: expenses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = expenses[index];
            final category = provider.getCategoryById(tx.categoryId);
            return _buildTransactionItem(context, tx, category, provider);
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionModel tx,
    category,
    ExpenseProvider provider,
  ) {
    final bool isExpense = tx.isExpense;
    final color = isExpense ? IconHelpers.parseColor(category?.colorCode) : Colors.greenAccent;
    final iconData = isExpense ? IconHelpers.getIcon(category?.iconCode) : Icons.payments;

    return Dismissible(
      key: Key('report_tx_${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteTransaction(tx.id!),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddExpenseScreen(transaction: tx)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                radius: 24,
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.notes?.isNotEmpty == true ? tx.notes! : (category?.name ?? 'Unknown'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${tx.date.day}/${tx.date.month}/${tx.date.year}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '-\$${tx.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFff6b6b),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────── SAVINGS TAB ────────────────────────

  Widget _buildSavingsTab() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final income = provider.getMonthlyTotal(_viewMonth.year, _viewMonth.month, isExpense: false);
        final expenses = provider.getMonthlyTotal(_viewMonth.year, _viewMonth.month, isExpense: true);
        final savings = income - expenses;
        final savingsRate = income > 0 ? (savings / income * 100) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              _buildSavingsCard(context, income, expenses, savings, savingsRate),
              const SizedBox(height: 16),
              _buildSixMonthChart(context, provider),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavingsCard(
    BuildContext context,
    double income,
    double expenses,
    double savings,
    double savingsRate,
  ) {
    final isPositive = savings >= 0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MONTHLY SAVINGS',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}\$${savings.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isPositive ? const Color(0xFF39ff14) : const Color(0xFFff6b6b),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Savings rate: ${savingsRate.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSavingsStatItem('Income', income, const Color(0xFF39ff14))),
              const SizedBox(width: 16),
              Expanded(child: _buildSavingsStatItem('Expenses', expenses, const Color(0xFFff6b6b))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsStatItem(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSixMonthChart(BuildContext context, ExpenseProvider provider) {
    final now = DateTime.now();
    final List<BarChartGroupData> groups = [];
    final List<String> labels = [];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final income = provider.getMonthlyTotal(month.year, month.month, isExpense: false);
      final expenses = provider.getMonthlyTotal(month.year, month.month, isExpense: true);
      labels.add(_monthNames[month.month].substring(0, 3));
      groups.add(
        BarChartGroupData(
          x: 5 - i,
          barRods: [
            BarChartRodData(
                toY: income,
                color: const Color(0xFF39ff14),
                width: 8,
                borderRadius: BorderRadius.circular(4)),
            BarChartRodData(
                toY: expenses,
                color: const Color(0xFFff6b6b),
                width: 8,
                borderRadius: BorderRadius.circular(4)),
          ],
          barsSpace: 4,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('6-Month Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendDot(const Color(0xFF39ff14), 'Income'),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFFff6b6b), 'Expenses'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(labels[idx],
                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // ──────────────────────── BOTTOM NAV ────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 10,
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context, Icons.home, 'Home', false, () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (ctx, anim1, anim2) => const DashboardScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }),
              _buildNavItem(context, Icons.analytics, 'Insights', true, () {}),
              _buildNavItem(context, Icons.account_balance_wallet, 'Wallets', false, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wallets coming soon!')),
                );
              }),
              _buildNavItem(context, Icons.person, 'Profile', false, () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (ctx, anim1, anim2) => const ProfileScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
