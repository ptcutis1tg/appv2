import 'dart:math';

import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/budget_repository.dart';
import 'package:appv2/db/category_repository.dart';
import 'package:appv2/screens/budget_category_detail_screen.dart';
import 'package:appv2/theme/app_theme.dart';
import 'package:appv2/widgets/shared/bottom_nav_bar.dart';
import 'package:appv2/widgets/shared/category_progress_item.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:appv2/widgets/shared/section_header.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MonthlyBudgetScreen extends StatefulWidget {
  const MonthlyBudgetScreen({
    super.key,
    this.embedded = false,
    this.onNavigate,
    this.refreshSignal = 0,
  });

  final bool embedded;
  final ValueChanged<int>? onNavigate;
  final int refreshSignal;

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen> {
  final _budgetRepo = BudgetRepository();
  final _categoryRepo = CategoryRepository();
  final _amountController = TextEditingController();
  final _rng = Random();
  static const _newCategoryIcons = <IconData>[
    Icons.pets,
    Icons.fitness_center,
    Icons.school,
    Icons.local_hospital,
    Icons.movie,
    Icons.sports_esports,
    Icons.celebration,
    Icons.card_giftcard,
    Icons.star,
  ];
  static const _colorChoices = <Color>[
    Color(0xFF13EC5B),
    Color(0xFF22C55E),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFFEF4444),
    Color(0xFFF43F5E),
  ];

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
  void didUpdateWidget(covariant MonthlyBudgetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _loadBudgets();
    }
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
    final dbCategories = await _categoryRepo.getAllCategories();
    if (!mounted) return;
    final categories = <CategoryData>[
      ...dbCategories,
      ...kQuickCategories.where(
        (quick) => !dbCategories.any((db) => db.id == quick.id),
      ),
    ];
    if (categories.isEmpty) {
      categories.addAll(kQuickCategories);
    }

    CategoryData selectedCategory = categories.first;
    final iconScrollController = ScrollController();
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
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thiết lập ngân quỹ',
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
                      'Hạng mục',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final created = await _openCreateCategoryDialog();
                          if (created == null) return;
                          setModalState(() {
                            categories.add(created);
                            selectedCategory = created;
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Hạng mục mới'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 92,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          if (!iconScrollController.hasClients) return;
                          final pos = iconScrollController.position;
                          final next =
                              (iconScrollController.offset - details.delta.dx)
                                  .clamp(
                                    pos.minScrollExtent,
                                    pos.maxScrollExtent,
                                  );
                          iconScrollController.jumpTo(next);
                        },
                        child: ListView.separated(
                          controller: iconScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = selectedCategory.id == cat.id;
                            return InkWell(
                              onTap: () =>
                                  setModalState(() => selectedCategory = cat),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: isSelected
                                      ? colors.primary.withValues(alpha: 0.16)
                                      : colors.onSurface.withValues(
                                          alpha: 0.04,
                                        ),
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurface.withValues(
                                            alpha: 0.12,
                                          ),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(cat.icon, color: colors.primary),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Hạn mức chi tiêu (USD)',
                        hintText: 'Ví dụ: 1000',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final value = double.tryParse(
                            _amountController.text.trim(),
                          );
                          if (value == null || value <= 0) return;
                          await _saveBudget(selectedCategory, value);
                          if (!context.mounted) return;
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Lưu hạn mức'),
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
    iconScrollController.dispose();
  }

  Future<void> _saveBudget(CategoryData category, double budget) async {
    int categoryId;
    if (category.id == null) {
      categoryId = await _categoryRepo.insertCategory(category);
    } else {
      categoryId = category.id!;
      final existing = await _categoryRepo.getCategoryById(categoryId);
      if (existing == null) {
        categoryId = await _categoryRepo.insertCategory(category);
      }
    }

    await _budgetRepo.upsertBudget(categoryId, budget, _monthKey);
  }

  Future<void> _openEditBudgetSheet(BudgetItemData item) async {
    final categoryId = item.categoryId;
    if (categoryId == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BudgetCategoryDetailScreen(
          categoryId: categoryId,
          monthKey: _monthKey,
          monthLabel: _monthLabel,
          initialBudget: item.budget,
        ),
      ),
    );

    if (updated == true) {
      await _loadBudgets();
    }
  }

  Future<CategoryData?> _openCreateCategoryDialog() async {
    final nameController = TextEditingController();
    IconData selectedIcon = _newCategoryIcons.first;
    Color selectedColor = _colorChoices[_rng.nextInt(_colorChoices.length)];

    final created = await showDialog<CategoryData>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colors.primary.withValues(alpha: 0.25)),
              ),
              title: const Text('Them hang muc moi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ten hang muc',
                        hintText: 'Vi du: Thu cung',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Chon icon'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _newCategoryIcons.map((icon) {
                        final active = selectedIcon == icon;
                        return InkWell(
                          onTap: () =>
                              setDialogState(() => selectedIcon = icon),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: active
                                  ? colors.primary.withValues(alpha: 0.18)
                                  : colors.onSurface.withValues(alpha: 0.06),
                              border: Border.all(
                                color: active
                                    ? colors.primary
                                    : colors.onSurface.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Icon(icon, color: colors.primary),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('Chon mau'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._colorChoices.map((c) {
                          final active = selectedColor == c;
                          return InkWell(
                            onTap: () =>
                                setDialogState(() => selectedColor = c),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: active
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedColor =
                                  _colorChoices[_rng.nextInt(
                                    _colorChoices.length,
                                  )];
                            });
                          },
                          icon: const Icon(Icons.shuffle),
                          tooltip: 'Mau ngau nhien',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Huy'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(context).pop(
                      CategoryData(
                        name: name,
                        icon: selectedIcon,
                        color: selectedColor,
                      ),
                    );
                  },
                  child: const Text('Them'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    return created;
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _BudgetSummaryCard(
                      colors: colors,
                      theme: theme,
                      totalBudget: '\$${_formatVnd(_totalBudget)}',
                      usedPercent: _usedPercent,
                      remainingLabel:
                          'Remaining \$${_formatVnd((_totalBudget - _totalSpent).clamp(0, double.infinity))}',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: SectionHeader(title: 'Budget Categories'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: const {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.invertedStylus,
                          PointerDeviceKind.unknown,
                        },
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _CategoryBudgets(
                              theme: theme,
                              budgets: _budgets,
                              onItemTap: _openEditBudgetSheet,
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : BottomNavBar(
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
  const _CategoryBudgets({
    required this.theme,
    required this.budgets,
    required this.onItemTap,
  });

  final ThemeData theme;
  final List<BudgetItemData> budgets;
  final ValueChanged<BudgetItemData> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No budget set yet', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return Column(
      children: budgets.map((item) {
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
            progressColor: _statusColor(item),
            amountLabel: amountText,
            percentLabel: '${pct.toInt()}%',
            subtitleLabel: subLabel,
            amountColor: item.isOverBudget
                ? AppTheme.accentRed
                : pct > 90
                ? AppTheme.accentYellow
                : null,
            onTap: () => onItemTap(item),
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(BudgetItemData item) {
    final diff = item.spent - item.budget;
    if (diff > 0.01) {
      return AppTheme.accentRed;
    }
    if (diff.abs() <= 0.01) {
      return AppTheme.accentYellow;
    }
    return const Color(0xFF13EC5B);
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
