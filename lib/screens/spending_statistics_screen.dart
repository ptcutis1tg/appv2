import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:appv2/data/mock_data.dart';
import 'package:appv2/widgets/shared/bottom_nav_bar.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:appv2/widgets/shared/segmented_toggle.dart';
import 'package:appv2/db/transaction_repository.dart';

/// Statistics screen: donut chart + category breakdown.
class SpendingStatisticsScreen extends StatefulWidget {
  const SpendingStatisticsScreen({super.key});

  @override
  State<SpendingStatisticsScreen> createState() =>
      _SpendingStatisticsScreenState();
}

class _SpendingStatisticsScreenState extends State<SpendingStatisticsScreen> {
  int _reportType = 0; // 0 = Chi tiêu, 1 = Thu nhập
  final _txnRepo = TransactionRepository();
  bool _isLoading = true;
  List<TransactionData> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final txns = await _txnRepo.getAllTransactions();
    if (mounted) {
      setState(() {
        _allTransactions = txns;
        _isLoading = false;
      });
    }
  }

  List<StatsCategoryData> get _currentStats {
    final isIncome = _reportType == 1;
    final relevant = _allTransactions
        .where((t) => t.isIncome == isIncome)
        .toList();

    final Map<int, double> amountsByCat = {};
    final Map<int, CategoryData> catsById = {};

    for (final t in relevant) {
      final cid = t.category.id ?? 0;
      amountsByCat[cid] = (amountsByCat[cid] ?? 0) + t.amount;
      catsById[cid] = t.category;
    }

    final total = amountsByCat.values.fold(0.0, (sum, val) => sum + val);

    final stats = amountsByCat.entries.map((e) {
      final cid = e.key;
      final amount = e.value;
      final cat = catsById[cid]!;
      return StatsCategoryData(
        name: cat.name,
        color: cat.color,
        icon: cat.icon,
        amount: amount,
        percentage: total > 0 ? (amount / total * 100) : 0,
      );
    }).toList();

    stats.sort((a, b) => b.amount.compareTo(a.amount));
    return stats;
  }

  double get _totalAmount {
    final isIncome = _reportType == 1;
    return _allTransactions
        .where((t) => t.isIncome == isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
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
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: SegmentedToggle(
                      options: const ['Chi tiêu', 'Thu nhập'],
                      selectedIndex: _reportType,
                      onChanged: (i) => setState(() => _reportType = i),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _Summary(
                            theme: theme,
                            colors: colors,
                            label: _reportType == 0
                                ? 'Tổng chi tiêu'
                                : 'Tổng thu nhập',
                            amount: _totalAmount,
                          ),
                          _DonutChart(colors: colors, stats: _currentStats),
                          const SizedBox(height: 24),
                          _CategoryList(
                            theme: theme,
                            colors: colors,
                            stats: _currentStats,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Báo cáo
        showCenterFab: true,
        onFabTap: () {},
        onTap: (i) {
          if (i != 1) Navigator.of(context).pop();
        },
        items: const [
          BottomNavItem(icon: Icons.receipt_long, label: 'Giao dịch'),
          BottomNavItem(
            icon: Icons.pie_chart_outline,
            label: 'Báo cáo',
            filledIcon: Icons.pie_chart,
          ),
          BottomNavItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Ví',
          ),
          BottomNavItem(icon: Icons.settings_outlined, label: 'Cài đặt'),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.theme, required this.onBack});

  final ThemeData theme;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconCircleButton(icon: Icons.chevron_left, onTap: onBack),
          Text('Báo cáo', style: theme.textTheme.titleLarge),
          IconCircleButton(icon: Icons.calendar_today, onTap: () {}),
        ],
      ),
    );
  }
}

// ── Summary ──────────────────────────────────────────────────────────
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

// ── Donut Chart (CustomPainter) ──────────────────────────────────────
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
            'Chưa có dữ liệu',
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

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Segments
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

// ── Category List ────────────────────────────────────────────────────
class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.theme,
    required this.colors,
    required this.stats,
  });

  final ThemeData theme;
  final ColorScheme colors;
  final List<StatsCategoryData> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Danh mục', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        ...stats.map(
          (cat) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _StatsCategoryItem(cat: cat, colors: colors, theme: theme),
          ),
        ),
      ],
    );
  }
}

class _StatsCategoryItem extends StatelessWidget {
  const _StatsCategoryItem({
    required this.cat,
    required this.colors,
    required this.theme,
  });

  final StatsCategoryData cat;
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
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
                          valueColor: AlwaysStoppedAnimation<Color>(cat.color),
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
    );
  }
}
