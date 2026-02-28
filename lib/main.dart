import 'package:flutter/material.dart';
import 'package:appv2/theme/app_theme.dart';
import 'package:appv2/screens/ledger_home_screen.dart';
import 'package:appv2/screens/spending_statistics_screen.dart';
import 'package:appv2/screens/monthly_budget_screen.dart';
import 'package:appv2/screens/app_settings_screen.dart';
import 'package:appv2/screens/fast_entry_screen.dart';
import 'package:appv2/widgets/shared/bottom_nav_bar.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:appv2/db/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.instance.database;
  runApp(const SmartFinanceApp());
}

class SmartFinanceApp extends StatelessWidget {
  const SmartFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  int _refreshSignal = 0;

  Future<void> _openFastEntry() async {
    final created = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FastEntryScreen()));

    if (created == true && mounted) {
      setState(() => _refreshSignal++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LedgerHomeScreen(
            embedded: true,
            refreshSignal: _refreshSignal,
            onNavigate: (i) => setState(() => _currentIndex = i),
          ),
          SpendingStatisticsScreen(
            embedded: true,
            refreshSignal: _refreshSignal,
            onNavigate: (i) => setState(() => _currentIndex = i),
          ),
          MonthlyBudgetScreen(
            embedded: true,
            refreshSignal: _refreshSignal,
            onNavigate: (i) => setState(() => _currentIndex = i),
          ),
          AppSettingsScreen(
            embedded: true,
            onNavigate: (i) => setState(() => _currentIndex = i),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        showCenterFab: true,
        onFabTap: _openFastEntry,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavItem(
            icon: Icons.home_outlined,
            label: 'Trang chu',
            filledIcon: Icons.home,
          ),
          BottomNavItem(icon: Icons.bar_chart, label: 'Bao cao'),
          BottomNavItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Ngan quy',
            filledIcon: Icons.account_balance_wallet,
          ),
          BottomNavItem(icon: Icons.settings_outlined, label: 'Cai dat'),
        ],
      ),
    );
  }
}
