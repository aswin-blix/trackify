import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/transaction_model.dart';
import 'add_expense_screen.dart';
import 'monthly_report_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Text(
                  'Alex Johnson',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthHeader(),
              const SizedBox(height: 24),
              _buildBalanceCard(context),
              const SizedBox(height: 32),
              _buildQuickInsightsTitle(context),
              const SizedBox(height: 16),
              _buildQuickInsightsRow(context),
              const SizedBox(height: 32),
              _buildRecentTransactionsTitle(context),
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

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'October 2023', // Hardcoded to match mockup feeling, or could use current date
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Text(
              'This Month',
              style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            Icon(Icons.expand_more, color: Colors.blue.shade600, size: 16),
          ],
        )
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final bal = provider.balance;
        final expenses = provider.totalExpenses;
        final income = provider.totalIncome;

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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.15),
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
                        color: Colors.white.withOpacity(0.15),
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
        Text(
          'View All',
          style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildQuickInsightsRow(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        // Build mock summary row, normally drawn dynamically from categories.
        // For matching the mockup closely, using static dummy stats in UI.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildInsightCard('Food', Icons.restaurant, Colors.orange, '\$840.00'),
              const SizedBox(width: 16),
              _buildInsightCard('Transport', Icons.directions_car, Colors.blue, '\$210.00'),
              const SizedBox(width: 16),
              _buildInsightCard('Shopping', Icons.shopping_bag, Colors.purple, '\$1,150.00'),
              const SizedBox(width: 16),
              _buildInsightCard('Rent', Icons.home, Colors.green, '\$1,040.00'),
            ],
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
        color: const Color(0xFF1c2433).withOpacity(0.5),
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

  Widget _buildRecentTransactionsTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
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
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = provider.transactions[index];
            final category = provider.getCategoryById(tx.categoryId);
            return _buildTransactionItem(context, tx, category);
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx, category) {
    final bool isExpense = tx.isExpense;
    final colorString = category?.colorCode.replaceAll('#', '0xFF') ?? '0xFF94a3b8';
    final color = Color(int.parse(colorString));

    IconData iconData = Icons.receipt;
    if (category?.iconCode == 'restaurant') iconData = Icons.restaurant;
    if (category?.iconCode == 'directions_car') iconData = Icons.directions_car;
    if (category?.iconCode == 'shopping_bag') iconData = Icons.shopping_bag;
    if (category?.iconCode == 'home') iconData = Icons.home;

    if (!isExpense) {
      iconData = Icons.payments; 
      colorString.replaceAll(colorString, '0xFF39ff14'); // Green for income 
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isExpense ? color.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
            radius: 24,
            child: Icon(iconData, color: isExpense ? color : Colors.greenAccent, size: 24),
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
                    pageBuilder: (_, __, ___) => const MonthlyReportScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(context, Icons.account_balance_wallet, 'Wallets', false, () {}),
              _buildNavItem(context, Icons.person, 'Profile', false, () {}),
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
