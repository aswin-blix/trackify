import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/icon_helpers.dart';
import 'add_expense_screen.dart';
import 'monthly_report_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final userName = Provider.of<SettingsProvider>(context).userName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              child: Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthHeader(now),
              const SizedBox(height: 24),
              _buildBalanceCard(context, now),
              const SizedBox(height: 32),
              _buildQuickInsightsTitle(context),
              const SizedBox(height: 16),
              _buildQuickInsightsRow(context, now),
              const SizedBox(height: 32),
              _buildRecentTransactionsTitle(),
              const SizedBox(height: 16),
              _buildRecentTransactionsList(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildMonthHeader(DateTime now) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_monthNames[now.month]} ${now.year}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Text(
              'This Month',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.expand_more, color: Colors.blue.shade600, size: 16),
          ],
        )
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, DateTime now) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final bal = provider.balance;
        final expenses = provider.getMonthlyTotal(now.year, now.month, isExpense: true);
        final income = provider.getMonthlyTotal(now.year, now.month, isExpense: false);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Colors.blue.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${bal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly Spending',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('\$${expenses.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly Income',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('\$${income.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickInsightsTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Quick Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (ctx, anim1, anim2) => const MonthlyReportScreen(),
                transitionDuration: Duration.zero,
              ),
            );
          },
          child: Text(
            'View All',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInsightsRow(BuildContext context, DateTime now) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final groupedData = provider.getExpensesByCategory(now.year, now.month);

        if (groupedData.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1c2433).withValues(alpha: 0.5),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'No expenses yet this month.\nTap + to add one!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }

        final sortedEntries = groupedData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topEntries = sortedEntries.take(4).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: topEntries.map((entry) {
              final cat = provider.getCategoryById(entry.key);
              final color = IconHelpers.parseColor(cat?.colorCode);
              final icon = IconHelpers.getIcon(cat?.iconCode);
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildInsightCard(
                  cat?.name ?? 'Other',
                  icon,
                  color,
                  '\$${entry.value.toStringAsFixed(2)}',
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(String title, IconData icon, Color color, String amount) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2433).withValues(alpha: 0.5),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsTitle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Icon(Icons.filter_list, color: Colors.grey),
      ],
    );
  }

  Widget _buildRecentTransactionsList(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text("No transactions yet. Tap + to add one!"),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.transactions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = provider.transactions[index];
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
      key: Key('tx_${tx.id}'),
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
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(transaction: tx),
            ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isExpense ? const Color(0xFFff6b6b) : const Color(0xFF39ff14),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category?.name.toUpperCase() ?? 'OTHER',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 10,
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(context, Icons.home, 'Home', true, () {}),
              _buildNavItem(context, Icons.analytics, 'Insights', false, () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (ctx, anim1, anim2) => const MonthlyReportScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }),
              const SizedBox(width: 48),
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

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey, size: 24),
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
