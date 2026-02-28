import 'dart:math' as math;

import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/transaction_repository.dart';
import 'package:appv2/screens/category_detail_screen.dart';
import 'package:appv2/widgets/shared/bottom_nav_bar.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:appv2/widgets/shared/segmented_toggle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SpendingStatisticsScreen extends StatefulWidget {
  const SpendingStatisticsScreen({
    super.key,
    this.embedded = false,
    this.onNavigate,
    this.refreshSignal = 0,
  });

  final bool embedded;
  final ValueChanged<int>? onNavigate;
  final int refreshSignal;

  @override
  State<SpendingStatisticsScreen> createState() =>
      _SpendingStatisticsScreenState();
}

class _SpendingStatisticsScreenState extends State<SpendingStatisticsScreen> {
  static const _k7d = '7D';
  static const _k30d = '30D';
  static const _k90d = '90D';
  static const _kYtd = 'YTD';
  static const _kAll = 'All';
  static const _kFromDate = 'From';

  int _reportType = 0; // 0 = expense, 1 = income
  String _timeFilter = _k30d;
  DateTime? _customFromDate;
  bool _isLoading = true;
  final _txnRepo = TransactionRepository();
  List<TransactionData> _allTransactions = [];
  static const _colorChoices = <Color>[
    Color(0xFF22C55E),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFFEF4444),
    Color(0xFFF43F5E),
    Color(0xFF14B8A6),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant SpendingStatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final txns = await _txnRepo.getAllTransactions();
    if (!mounted) return;
    setState(() {
      _allTransactions = txns;
      _isLoading = false;
    });
  }

  DateTime? _startDate(DateTime now) {
    switch (_timeFilter) {
      case _k7d:
        return now.subtract(const Duration(days: 7));
      case _k30d:
        return now.subtract(const Duration(days: 30));
      case _k90d:
        return now.subtract(const Duration(days: 90));
      case _kYtd:
        return DateTime(now.year, 1, 1);
      case _kFromDate:
        return _customFromDate;
      case _kAll:
        return null;
    }
    return null;
  }

  List<TransactionData> get _transactionsInScope {
    final now = DateTime.now();
    final start = _startDate(now);
    if (start == null) return _allTransactions;

    return _allTransactions.where((t) {
      final date = DateTime.tryParse(t.date ?? '');
      if (date == null) return false;
      return !date.isBefore(start) && !date.isAfter(now);
    }).toList();
  }

  List<TransactionData> get _reportTransactions {
    final isIncome = _reportType == 1;
    return _transactionsInScope.where((t) => t.isIncome == isIncome).toList();
  }

  double get _totalAmount =>
      _reportTransactions.fold(0.0, (sum, t) => sum + t.amount);

  List<StatsCategoryData> get _currentStats {
    final amountsByCat = <int, double>{};
    final catsById = <int, CategoryData>{};

    for (final t in _reportTransactions) {
      final cid = t.category.id ?? 0;
      amountsByCat[cid] = (amountsByCat[cid] ?? 0) + t.amount;
      catsById[cid] = t.category;
    }

    final total = amountsByCat.values.fold(0.0, (sum, val) => sum + val);
    final stats = amountsByCat.entries.map((e) {
      final cat = catsById[e.key]!;
      final amount = e.value;
      return StatsCategoryData(
        categoryId: cat.id,
        name: cat.name,
        icon: cat.icon,
        amount: amount,
        percentage: total > 0 ? (amount / total * 100) : 0,
        color: _displayCategoryColor(cat),
      );
    }).toList();

    stats.sort((a, b) => b.amount.compareTo(a.amount));
    return stats;
  }

  Color _displayCategoryColor(CategoryData category) {
    // Default green categories get a deterministic "random-like" color for better visual separation.
    if (category.color == const Color(0xFF13EC5B)) {
      final seed = (category.id ?? category.name.hashCode).abs();
      return _colorChoices[seed % _colorChoices.length];
    }
    return category.color;
  }

  Future<void> _openCategoryDetail(StatsCategoryData stat) async {
    final categoryId = stat.categoryId;
    if (categoryId == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(categoryId: categoryId),
      ),
    );
    if (changed == true && mounted) {
      _loadData();
    }
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customFromDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _customFromDate = picked;
      _timeFilter = _kFromDate;
    });
  }

  String _rangeLabel() {
    if (_timeFilter == _kAll) return 'All time';
    if (_timeFilter == _kYtd) return 'From Jan 1 until now';
    if (_timeFilter == _kFromDate && _customFromDate != null) {
      final d = _customFromDate!;
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      return 'From $day/$month/${d.year} until now';
    }
    return 'Last ${_timeFilter.toLowerCase()}';
  }

  Widget _timeButton(String value) {
    final active = _timeFilter == value;
    return GestureDetector(
      onTap: () {
        if (value == _kFromDate) {
          _pickFromDate();
          return;
        }
        setState(() {
          _timeFilter = value;
        });
      },
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : null,
          border: Border.all(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
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
                    onBack: () {
                      if (widget.embedded) {
                        widget.onNavigate?.call(0);
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    onPickFromDate: _pickFromDate,
                    embedded: widget.embedded,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: SegmentedToggle(
                      options: const ['Chi tieu', 'Thu nhap'],
                      selectedIndex: _reportType,
                      onChanged: (i) => setState(() => _reportType = i),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _timeButton(_k7d)),
                        const SizedBox(width: 6),
                        Expanded(child: _timeButton(_k30d)),
                        const SizedBox(width: 6),
                        Expanded(child: _timeButton(_k90d)),
                        const SizedBox(width: 6),
                        Expanded(child: _timeButton(_kYtd)),
                        const SizedBox(width: 6),
                        Expanded(child: _timeButton(_kAll)),
                        const SizedBox(width: 6),
                        Expanded(child: _timeButton(_kFromDate)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _rangeLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  _Summary(
                    theme: theme,
                    colors: colors,
                    label: _reportType == 0 ? 'Tong chi tieu' : 'Tong thu nhap',
                    amount: _totalAmount,
                  ),
                  _DonutChart(colors: colors, stats: _currentStats),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Danh muc', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(
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
                                child: Column(
                                  children: [
                                    _CategoryList(
                                      theme: theme,
                                      colors: colors,
                                      stats: _currentStats,
                                      onCategoryTap: _openCategoryDetail,
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
                  ),
                ],
              ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : BottomNavBar(
              currentIndex: 1,
              showCenterFab: true,
              onFabTap: () {},
              onTap: (i) {
                if (i != 1) Navigator.of(context).pop();
              },
              items: const [
                BottomNavItem(icon: Icons.receipt_long, label: 'Giao dich'),
                BottomNavItem(
                  icon: Icons.pie_chart_outline,
                  label: 'Bao cao',
                  filledIcon: Icons.pie_chart,
                ),
                BottomNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Vi',
                ),
                BottomNavItem(icon: Icons.settings_outlined, label: 'Cai dat'),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.theme,
    required this.onBack,
    required this.onPickFromDate,
    required this.embedded,
  });

  final ThemeData theme;
  final VoidCallback onBack;
  final VoidCallback onPickFromDate;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          embedded
              ? const SizedBox(width: 48, height: 48)
              : IconCircleButton(icon: Icons.chevron_left, onTap: onBack),
          Text('Bao cao', style: theme.textTheme.titleLarge),
          IconCircleButton(icon: Icons.calendar_today, onTap: onPickFromDate),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.theme,
    required this.colors,
    required this.label,
    required this.amount,
  });

  final ThemeData theme;
  final ColorScheme colors;
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.colors, required this.stats});

  final ColorScheme colors;
  final List<StatsCategoryData> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return SizedBox(
        width: 220,
        height: 220,
        child: Center(
          child: Text(
            'Chua co du lieu',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _DonutPainter(
              segments: stats
                  .map(
                    (c) => _DonutSegment(
                      percentage: c.percentage / 100,
                      color: c.color,
                    ),
                  )
                  .toList(),
              backgroundColor: colors.onSurface.withValues(alpha: 0.06),
            ),
          ),
          Icon(Icons.analytics, size: 40, color: colors.primary),
        ],
      ),
    );
  }
}

class _DonutSegment {
  const _DonutSegment({required this.percentage, required this.color});
  final double percentage;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.backgroundColor});

  final List<_DonutSegment> segments;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 24.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    var startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweepAngle = 2 * math.pi * seg.percentage;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.theme,
    required this.colors,
    required this.stats,
    required this.onCategoryTap,
  });

  final ThemeData theme;
  final ColorScheme colors;
  final List<StatsCategoryData> stats;
  final ValueChanged<StatsCategoryData> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox();

    return Column(
      children: stats
          .map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _StatsCategoryItem(
                cat: cat,
                colors: colors,
                theme: theme,
                onTap: () => onCategoryTap(cat),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatsCategoryItem extends StatelessWidget {
  const _StatsCategoryItem({
    required this.cat,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final StatsCategoryData cat;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cat.color,
                shape: BoxShape.circle,
              ),
              child: Icon(cat.icon, color: colors.onPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat.name, style: theme.textTheme.titleSmall),
                      Text(
                        '\$${cat.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: cat.percentage / 100,
                            minHeight: 6,
                            backgroundColor: colors.onSurface.withValues(
                              alpha: 0.08,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cat.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${cat.percentage.toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
