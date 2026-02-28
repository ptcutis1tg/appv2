import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/budget_repository.dart';
import 'package:appv2/db/category_repository.dart';
import 'package:appv2/theme/app_theme.dart';
import 'package:appv2/widgets/shared/bottom_nav_bar.dart';
import 'package:appv2/widgets/shared/category_progress_item.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:appv2/widgets/shared/section_header.dart';
import 'package:flutter/material.dart';

class MonthlyBudgetScreen extends StatefulWidget {
  const MonthlyBudgetScreen({super.key});

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen> {
  final _budgetRepo = BudgetRepository();
  final _categoryRepo = CategoryRepository();
  final _amountController = TextEditingController();

  List<BudgetItemData> _budgets = [];
  bool _isLoading = true;

  String get _monthKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }

  String get _monthLabel {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    final budgets = await _budgetRepo.getBudgetsByMonth(_monthKey);
    if (!mounted) return;
    setState(() {
      _budgets = budgets;
      _isLoading = false;
    });
  }

  Future<void> _openAddBudgetSheet() async {
    CategoryData selectedCategory = kQuickCategories.first;
    _amountController.clear();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Monthly Budget',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _monthLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kQuickCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final cat = kQuickCategories[index];
                          final isSelected = selectedCategory.id == cat.id;
                          return InkWell(
                            onTap: () => setModalState(() => selectedCategory = cat),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: isSelected
                                    ? colors.primary.withValues(alpha: 0.16)
                                    : colors.onSurface.withValues(alpha: 0.04),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.onSurface.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(cat.icon, color: colors.primary),
                                  const SizedBox(height: 6),
                                  Text(
                                    cat.name,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Budget amount (USD)',
                        hintText: 'e.g. 1000',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final value = double.tryParse(_amountController.text.trim());
                          if (value == null || value <= 0) return;
                          await _saveBudget(selectedCategory, value);
                          if (!context.mounted) return;
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Save Budget'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      await _loadBudgets();
    }
  }

  Future<void> _saveBudget(CategoryData category, double budget) async {
    final id = category.id;
    if (id == null) return;

    final existing = await _categoryRepo.getCategoryById(id);
    if (existing == null) {
      await _categoryRepo.insertCategory(category);
    }

    await _budgetRepo.upsertBudget(id, budget, _monthKey);
  }

  double get _totalBudget => _budgets.fold(0, (sum, b) => sum + b.budget);
  double get _totalSpent => _budgets.fold(0, (sum, b) => sum + b.spent);
  int get _usedPercent =>
      _totalBudget > 0 ? (_totalSpent / _totalBudget * 100).toInt() : 0;

  String _formatVnd(double v) {
    if (v == 0) return '0';
    final intVal = v.toInt();
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return formatted.endsWith(',')
        ? formatted.substring(0, formatted.length - 1)
        : formatted;
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
                  _Header(
                    theme: theme,
                    colors: colors,
                    monthLabel: _monthLabel,
                    onAddTap: _openAddBudgetSheet,
                  ),
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
                            totalBudget: '\$${_formatVnd(_totalBudget)}',
                            usedPercent: _usedPercent,
                            remainingLabel:
                                'Remaining \$${_formatVnd((_totalBudget - _totalSpent).clamp(0, double.infinity))}',
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
        currentIndex: 2,
        onTap: (i) {
          if (i != 2) Navigator.of(context).pop();
        },
        items: const [
          BottomNavItem(icon: Icons.home_outlined, label: 'Home'),
          BottomNavItem(icon: Icons.bar_chart, label: 'Report'),
          BottomNavItem(
            icon: Icons.account_balance_wallet,
            label: 'Budget',
            filledIcon: Icons.account_balance_wallet,
          ),
          BottomNavItem(icon: Icons.settings_outlined, label: 'Settings'),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.theme,
    required this.colors,
    required this.monthLabel,
    required this.onAddTap,
  });

  final ThemeData theme;
  final ColorScheme colors;
  final String monthLabel;
  final VoidCallback onAddTap;

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
                monthLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Budget',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          IconCircleButton(icon: Icons.add, onTap: onAddTap),
        ],
      ),
    );
  }
}

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
                'TOTAL BUDGET',
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
                  '$usedPercent% used',
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
            'No budget set yet',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: [
        const SectionHeader(
          title: 'Budget Categories',
          actionLabel: 'View all',
        ),
        const SizedBox(height: 24),
        ...budgets.map((item) {
          final pct = item.percentage;
          final amountText = _formatBudgetAmount(item.spent, item.budget);

          final remaining = item.budget - item.spent;
          final subLabel = remaining >= 0
              ? 'Remaining ${_formatVnd(remaining)}'
              : 'Over ${_formatVnd(-remaining)}';

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
    if (v == 0) return '0';
    final intVal = v.toInt();
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '\$${formatted.endsWith(',') ? formatted.substring(0, formatted.length - 1) : formatted}';
  }

  String _formatBudgetAmount(double spent, double budget) {
    return '${_formatVnd(spent)} / ${_formatVnd(budget)}';
  }
}
