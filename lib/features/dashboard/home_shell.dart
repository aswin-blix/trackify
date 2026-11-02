import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../app_lock/app_lock_screen.dart';
import '../household/household_sync.dart';
import '../debts/debt_providers.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _currentTab = 0;

  /// Set when the app leaves the foreground; checked on resume.
  bool _wentToBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Run after first frame so the shell is on screen before any I/O.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(householdSyncProvider).ensureStarted();
      _runAutoBackup();
      _onForeground();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Flutter >= 3.13 passes through `hidden` and `inactive` on the way back
    // to `resumed`, so compare against a flag rather than the previous state.
    switch (state) {
      case AppLifecycleState.paused:
        _wentToBackground = true;
      case AppLifecycleState.resumed:
        if (!_wentToBackground) return;
        _wentToBackground = false;
        final settings = ref.read(settingsProvider);
        if (settings.appLockEnabled && !AppLockGuard.suppressed && mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/lock', (route) => false);
          return;
        }
        ref.read(householdSyncProvider).ensureStarted();
        _runAutoBackup();
        _onForeground();
      default:
        break;
    }
  }

  /// Work that should happen whenever the user comes back to the app.
  Future<void> _onForeground() async {
    await _postRecurring();
    await _syncSmsQuietly();
    // Keep loan due reminders in line with what is still outstanding,
    // including entries that arrived from a partner's phone.
    await ref.read(debtReminderSyncProvider)();
  }

  Future<void> _postRecurring() async {
    final added = await ref.read(recurringProvider.notifier).postDue();
    if (added == 0 || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $added recurring transaction'
            '${added == 1 ? '' : 's'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _syncSmsQuietly() async {
    final settings = ref.read(settingsProvider);
    if (!settings.smsReaderEnabled) return;
    try {
      final service = ref.read(smsServiceProvider);
      if (!await service.hasPermission()) return;
      final result = await service.syncSms(settings.knownSenderIds);
      ref.read(smsProvider.notifier).refresh();
      if (result.added > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.added} new bank SMS to review'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Review',
              onPressed: () => Navigator.of(context).pushNamed('/sms'),
            ),
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.e('HomeShell', 'Background SMS scan failed', e, stack);
    }
  }

  Future<void> _runAutoBackup() async {
    try {
      final path = await ref.read(backupRepoProvider).runAutoBackupIfDue();
      if (path != null && mounted) {
        ref.read(settingsProvider.notifier).reload();
      }
    } catch (e, stack) {
      AppLogger.e('HomeShell', 'Auto backup check failed', e, stack);
    }
  }

  // Map: tab index accounting for FAB in center (index 2)
  // Actual screens: 0=Home, 1=Transactions, 3=Analytics, 4=Settings
  // FAB at index 2 opens Add Transaction sheet

  Widget _buildScreen() {
    switch (_currentTab) {
      case 1:
        return TransactionsScreen(onAddTransaction: _openAddTransaction);
      case 3:
        return const AnalyticsScreen();
      case 4:
        return const SettingsScreen();
      default:
        return DashboardScreen(
          onAddTransaction: _openAddTransaction,
          onViewAllTransactions: () => setState(() => _currentTab = 1),
        );
    }
  }

  void _onTabTap(int index) {
    if (index == 2) {
      _openAddTransaction();
      return;
    }
    setState(() => _currentTab = index);
  }

  void _openAddTransaction([TransactionType? initialType]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => AddTransactionScreen(initialType: initialType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark ? darkBackgroundGradient() : lightBackgroundGradient(),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_currentTab),
            child: _buildScreen(),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentTab,
        onTap: _onTabTap,
      ),
    );
  }
}
