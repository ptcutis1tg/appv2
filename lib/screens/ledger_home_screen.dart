import 'package:flutter/material.dart';
import 'package:appv2/data/mock_data.dart';
import 'package:appv2/theme/app_theme.dart';
import 'package:appv2/widgets/shared/bottom_nav_bar.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:appv2/widgets/shared/section_header.dart';
import 'package:appv2/widgets/shared/transaction_item.dart';
import 'package:appv2/screens/fast_entry_screen.dart';
import 'package:appv2/screens/spending_statistics_screen.dart';
import 'package:appv2/screens/monthly_budget_screen.dart';
import 'package:appv2/screens/app_settings_screen.dart';
import 'package:appv2/screens/database_debug_screen.dart';
import 'package:appv2/screens/transaction_history_screen.dart';
import 'package:appv2/screens/transaction_detail_screen.dart';
import 'package:appv2/db/transaction_repository.dart';
import 'package:appv2/db/user_repository.dart';

/// Home screen showing balance, income/expense summary, and transactions.
class LedgerHomeScreen extends StatefulWidget {
  const LedgerHomeScreen({
    super.key,
    this.embedded = false,
    this.onNavigate,
    this.refreshSignal = 0,
  });

  final bool embedded;
  final ValueChanged<int>? onNavigate;
  final int refreshSignal;

  @override
  State<LedgerHomeScreen> createState() => _LedgerHomeScreenState();
}

class _LedgerHomeScreenState extends State<LedgerHomeScreen> {
  static const int _historyPreviewLimit = 4;
  int _navIndex = 0;
  final _txnRepo = TransactionRepository();
  final _userRepo = UserRepository();

  List<TransactionData> _transactions = [];
  UserProfileData? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant LedgerHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final txns = await _txnRepo.getAllTransactions();
    final user = await _userRepo.getUser();
    if (mounted) {
      setState(() {
        _transactions = txns;
        _userProfile = user;
        _isLoading = false;
      });
    }
  }

  double get _income => _transactions
      .where((t) => t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);
  double get _expense => _transactions
      .where((t) => !t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);
  double get _balance => _income - _expense;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatTransactionDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '--/--/----';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return '--/--/----';
    return _formatDate(parsed);
  }

  Future<void> _openFastEntry() async {
    final created = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FastEntryScreen()));

    if (created == true && mounted) {
      _loadData();
    }
  }

  Future<void> _openAllHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionHistoryScreen(transactions: _transactions),
      ),
    );
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openTransactionDetails(TransactionData transaction) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: transaction),
      ),
    );

    if (changed == true && mounted) {
      _loadData();
    }
  }

  void _onNavTap(int index) {
    if (index == _navIndex && !widget.embedded) return;
    if (widget.embedded) {
      widget.onNavigate?.call(index);
      return;
    }
    switch (index) {
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SpendingStatisticsScreen()),
        );
        break;
      case 2:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MonthlyBudgetScreen()));
        break;
      case 3:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AppSettingsScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _TopHeader(
                    colors: colors,
                    theme: theme,
                    profile: _userProfile,
                    currentDateLabel: _formatDate(DateTime.now()),
                    onOpenDebug: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DatabaseDebugScreen(),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _BalanceHero(
                            colors: colors,
                            theme: theme,
                            balance: _balance,
                            income: _income,
                            expense: _expense,
                          ),
                          const SizedBox(height: 24),
                          _TransactionHistory(
                            theme: theme,
                            transactions: _transactions,
                            formatDate: _formatTransactionDate,
                            previewLimit: _historyPreviewLimit,
                            onViewAll: _openAllHistory,
                            onTransactionTap: _openTransactionDetails,
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : BottomNavBar(
              currentIndex: _navIndex,
              showCenterFab: true,
              onFabTap: _openFastEntry,
              onTap: _onNavTap,
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
                ),
                BottomNavItem(icon: Icons.settings_outlined, label: 'Cai dat'),
              ],
            ),
    );
  }
}

// ── Top Header ───────────────────────────────────────────────────────
class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.colors,
    required this.theme,
    required this.profile,
    required this.currentDateLabel,
    required this.onOpenDebug,
  });

  final ColorScheme colors;
  final ThemeData theme;
  final UserProfileData? profile;
  final String currentDateLabel;
  final VoidCallback onOpenDebug;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconCircleButton(icon: Icons.menu, onTap: onOpenDebug),
          Column(
            children: [
              Text('Real-time Ledger', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                currentDateLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          profile == null
              ? CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: colors.primary),
                )
              : ClipOval(
                  child: Image.network(
                    profile!.avatarUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CircleAvatar(
                      radius: 20,
                      backgroundColor: colors.primary.withValues(alpha: 0.2),
                      child: Icon(Icons.person, color: colors.primary),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Balance Hero Section ─────────────────────────────────────────────
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.colors,
    required this.theme,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final ColorScheme colors;
  final ThemeData theme;
  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          'SỐ DƯ HIỆN TẠI',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.primary.withValues(alpha: 0.6),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${balance.toStringAsFixed(2)}',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Thu nhập',
                amount: '\$${income.toStringAsFixed(2)}',
                change: '',
                icon: Icons.arrow_downward,
                iconColor: colors.primary,
                changeColor: colors.primary,
                colors: colors,
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                label: 'Chi tiêu',
                amount: '\$${expense.toStringAsFixed(2)}',
                change: '',
                icon: Icons.arrow_upward,
                iconColor: AppTheme.accentRose,
                changeColor: AppTheme.accentRose,
                colors: colors,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.change,
    required this.icon,
    required this.iconColor,
    required this.changeColor,
    required this.colors,
    required this.theme,
  });

  final String label;
  final String amount;
  final String change;
  final IconData icon;
  final Color iconColor;
  final Color changeColor;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (change.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              change,
              style: theme.textTheme.bodySmall?.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Transaction History ──────────────────────────────────────────────
class _TransactionHistory extends StatelessWidget {
  const _TransactionHistory({
    required this.theme,
    required this.transactions,
    required this.formatDate,
    required this.previewLimit,
    required this.onViewAll,
    required this.onTransactionTap,
  });

  final ThemeData theme;
  final List<TransactionData> transactions;
  final String Function(String?) formatDate;
  final int previewLimit;
  final VoidCallback onViewAll;
  final ValueChanged<TransactionData> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'Chua co giao dich nao',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final preview = transactions.take(previewLimit).toList();
    final grouped = <String, List<TransactionData>>{};
    for (final t in preview) {
      final key = formatDate(t.date);
      grouped.putIfAbsent(key, () => <TransactionData>[]).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Lich su giao dich',
          actionLabel: 'Tat ca',
          onAction: onViewAll,
        ),
        const SizedBox(height: 16),
        ...grouped.entries.expand(
          (entry) => [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                entry.key,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...entry.value.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TransactionItem(
                  icon: t.category.icon,
                  iconBackgroundColor: t.category.color,
                  iconColor: t.category.color,
                  title: t.title,
                  subtitle: t.subtitle,
                  amount: t.isIncome
                      ? '+\$${t.amount.toStringAsFixed(2)}'
                      : '-\$${t.amount.toStringAsFixed(2)}',
                  isIncome: t.isIncome,
                  onTap: () => onTransactionTap(t),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ],
    );
  }
}
