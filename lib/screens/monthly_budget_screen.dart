import 'package:flutter/material.dart';
import 'package:appv2/data/mock_data.dart';
import 'package:appv2/theme/app_theme.dart';
import 'package:appv2/widgets/shared/bottom_nav_bar.dart';
import 'package:appv2/widgets/shared/category_progress_item.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:appv2/widgets/shared/section_header.dart';
import 'package:appv2/db/budget_repository.dart';

/// Monthly budget screen with total summary and per-category breakdowns.
class MonthlyBudgetScreen extends StatefulWidget {
  const MonthlyBudgetScreen({super.key});

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen> {
  final _budgetRepo = BudgetRepository();
  List<BudgetItemData> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final budgets = await _budgetRepo.getBudgetsByMonth(
      '2023-10',
    ); // using mocked month for now
    if (mounted) {
      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    }
  }

  double get _totalBudget => _budgets.fold(0, (sum, b) => sum + b.budget);
  double get _totalSpent => _budgets.fold(0, (sum, b) => sum + b.spent);
  int get _usedPercent =>
      _totalBudget > 0 ? (_totalSpent / _totalBudget * 100).toInt() : 0;

  String _formatVnd(double v) {
    if (v == 0) return '0đ';
    final intVal = v.toInt();
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    // Remove trailing dot if exists
    return '${formatted.endsWith('.') ? formatted.substring(0, formatted.length - 1) : formatted}đ';
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
                  _Header(theme: theme, colors: colors),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          _BudgetSummaryCard(
                            colors: colors,
                            theme: theme,
                            totalBudget: _formatVnd(_totalBudget),
                            usedPercent: _usedPercent,
                            remainingLabel:
                                'Còn lại ${_formatVnd((_totalBudget - _totalSpent).clamp(0, double.infinity))}',
                          ),
                          const SizedBox(height: 32),
                          _CategoryBudgets(theme: theme, budgets: _budgets),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // Ngân quỹ
        onTap: (i) {
          if (i != 2) Navigator.of(context).pop();
        },
        items: const [
          BottomNavItem(icon: Icons.home_outlined, label: 'Trang chủ'),
          BottomNavItem(icon: Icons.bar_chart, label: 'Báo cáo'),
          BottomNavItem(
            icon: Icons.account_balance_wallet,
            label: 'Ngân quỹ',
            filledIcon: Icons.account_balance_wallet,
          ),
          BottomNavItem(icon: Icons.settings_outlined, label: 'Cài đặt'),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.theme, required this.colors});

  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kBudgetMonth,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ngân quỹ',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          IconCircleButton(icon: Icons.add, onTap: () {}),
        ],
      ),
    );
  }
}

// ── Budget Summary Card ──────────────────────────────────────────────
class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.colors,
    required this.theme,
    required this.totalBudget,
    required this.usedPercent,
    required this.remainingLabel,
  });

  final ColorScheme colors;
  final ThemeData theme;
  final String totalBudget;
  final int usedPercent;
  final String remainingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TỔNG NGÂN SÁCH',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.account_balance_wallet, color: colors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            totalBudget,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                remainingLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '$usedPercent% đã dùng',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (usedPercent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colors.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Budgets ─────────────────────────────────────────────────
class _CategoryBudgets extends StatelessWidget {
  const _CategoryBudgets({required this.theme, required this.budgets});

  final ThemeData theme;
  final List<BudgetItemData> budgets;

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Chưa có ngân sách nào',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: [
        const SectionHeader(
          title: 'Danh mục chi tiêu',
          actionLabel: 'Xem tất cả',
        ),
        const SizedBox(height: 24),
        ...budgets.map((item) {
          final pct = item.percentage;
          final amountText = _formatBudgetAmount(item.spent, item.budget);

          final remaining = item.budget - item.spent;
          final subLabel = remaining >= 0
              ? 'Còn lại ${_formatVnd(remaining)}'
              : 'Vượt ${_formatVnd(-remaining)}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: CategoryProgressItem(
              icon: item.icon,
              name: item.name,
              progressValue: item.budget > 0 ? item.spent / item.budget : 0,
              progressColor: item.progressColor,
              amountLabel: amountText,
              percentLabel: '${pct.toInt()}%',
              subtitleLabel: subLabel,
              amountColor: item.isOverBudget
                  ? AppTheme.accentRed
                  : pct > 90
                  ? AppTheme.accentYellow
                  : null,
            ),
          );
        }),
      ],
    );
  }

  String _formatVnd(double v) {
    if (v == 0) return '0đ';
    final intVal = v.toInt();
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '${formatted.endsWith('.') ? formatted.substring(0, formatted.length - 1) : formatted}đ';
  }

  String _formatBudgetAmount(double spent, double budget) {
    return '${_formatVnd(spent)} / ${_formatVnd(budget)}';
  }
}
