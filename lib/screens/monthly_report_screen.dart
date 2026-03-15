import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'dashboard_screen.dart';

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const DashboardScreen(),
                transitionDuration: Duration.zero,
              ),
            );
          },
        ),
        title: const Text('Monthly Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            _buildSummaryCard(context),
            const SizedBox(height: 16),
            _buildDonutChartSection(context),
            const SizedBox(height: 16),
            _buildInsightsList(context),
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTab('Overview', true, context),
          _buildTab('Expenses', false, context),
          _buildTab('Savings', false, context),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final totalExp = provider.totalExpenses;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
          ),
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey.withOpacity(0.05)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL EXPENSES', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('\$${totalExp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.trending_down, color: Color(0xFFff6b6b), size: 16),
                      SizedBox(width: 4),
                      Text('12.4%', style: TextStyle(color: Color(0xFFff6b6b), fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(width: 8),
                      Text('vs last month', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonutChartSection(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        final groupedData = provider.getExpensesByCategory(now.year, now.month);
        final totalExp = provider.totalExpenses;

        if (groupedData.isEmpty || totalExp == 0) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: const Center(child: Text("No expenses to chart yet.")),
          );
        }

        // Prepare FlChart Data
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

            final colorString = cat.colorCode.replaceAll('#', '0xFF');
            final color = Color(int.parse(colorString));
            final percentage = (amount / totalExp) * 100;

            sections.add(
              PieChartSectionData(
                color: color,
                value: amount,
                title: '',
                radius: 40,
              ),
            );

            legends.add(_buildLegendItem(color, cat.name, percentage));
          }
        });

        final topCat = provider.getCategoryById(maxCatId);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Expenses by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: sections,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('TOP SPEND', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(topCat?.name ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                          Text('\$${maxCatAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$name (${percentage.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildInsightsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smart Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: Icons.warning,
          iconColor: const Color(0xFFff7f50), // Coral
          title: 'Spending Alert',
          subtitle: 'Dining out is 30% higher than last month. Consider cooking at home more often.',
          bgColor: const Color(0xFFff7f50).withOpacity(0.1),
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFF39ff14), // Neon Green
          title: 'Savings Goal',
          subtitle: 'You\'re on track to reach your "New Car" goal by December. Keep it up!',
          bgColor: const Color(0xFF39ff14).withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildInsightItem({required IconData icon, required Color iconColor, required String title, required String subtitle, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
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
}
