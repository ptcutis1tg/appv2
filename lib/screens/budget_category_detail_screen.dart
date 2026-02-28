import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/budget_repository.dart';
import 'package:appv2/db/category_repository.dart';
import 'package:appv2/db/transaction_repository.dart';
import 'package:appv2/screens/transaction_detail_screen.dart';
import 'package:appv2/theme/app_theme.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:flutter/material.dart';

class BudgetCategoryDetailScreen extends StatefulWidget {
  const BudgetCategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.monthKey,
    required this.monthLabel,
    required this.initialBudget,
  });

  final int categoryId;
  final String monthKey;
  final String monthLabel;
  final double initialBudget;

  @override
  State<BudgetCategoryDetailScreen> createState() =>
      _BudgetCategoryDetailScreenState();
}

class _BudgetCategoryDetailScreenState
    extends State<BudgetCategoryDetailScreen> {
  final _budgetRepo = BudgetRepository();
  final _categoryRepo = CategoryRepository();
  final _txnRepo = TransactionRepository();
  final _budgetController = TextEditingController();

  CategoryData? _category;
  List<TransactionData> _transactions = [];
  bool _loading = true;
  bool _loadingTxns = true;
  bool _saving = false;
  bool _hasChanges = false;

  double get _spent => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _budgetValue => double.tryParse(_budgetController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _budgetController.text = widget.initialBudget.toStringAsFixed(2);
    _load();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cat = await _categoryRepo.getCategoryById(widget.categoryId);
    if (!mounted) return;
    if (cat == null) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _category = cat;
      _loading = false;
    });
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loadingTxns = true);
    final txns = await _txnRepo.getTransactionsByCategory(widget.categoryId);
    if (!mounted) return;
    setState(() {
      _transactions = txns;
      _loadingTxns = false;
    });
  }

  Future<void> _saveBudget() async {
    final budget = double.tryParse(_budgetController.text.trim());
    if (budget == null || budget <= 0) return;
    setState(() => _saving = true);
    await _budgetRepo.upsertBudget(widget.categoryId, budget, widget.monthKey);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _hasChanges = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Da luu ngan quy')));
  }

  Future<void> _deleteBudget() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa ngan quy'),
        content: const Text('Ban co chac chan muon xoa ngan quy hang muc nay?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoa'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _budgetRepo.deleteBudget(widget.categoryId, widget.monthKey);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Color _statusColor() {
    final diff = _spent - _budgetValue;
    if (diff > 0.01) return AppTheme.accentRed;
    if (diff.abs() <= 0.01) return AppTheme.accentYellow;
    return const Color(0xFF13EC5B);
  }

  String _formatDateTime(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return '--/--/---- --:--';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  Future<void> _openTransaction(TransactionData t) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: t),
      ),
    );
    if (changed == true && mounted) {
      _hasChanges = true;
      _loadTransactions();
    }
  }

  void _close() => Navigator.of(context).pop(_hasChanges);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cat = _category;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconCircleButton(
                          icon: Icons.chevron_left,
                          onTap: _close,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chi tiet ngan quy',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (cat != null)
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(cat.icon, color: cat.color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${cat.name} - ${widget.monthLabel}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Han muc chi tieu (USD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Da chi: \$${_spent.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          _spent > _budgetValue
                              ? 'Vuot muc'
                              : (_spent == _budgetValue
                                    ? 'Da cham muc'
                                    : 'Con trong muc'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _statusColor(),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _budgetValue > 0
                            ? (_spent / _budgetValue).clamp(0.0, 1.0)
                            : 0,
                        minHeight: 8,
                        backgroundColor: colors.onSurface.withValues(
                          alpha: 0.08,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _statusColor(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _deleteBudget,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.error,
                            ),
                            child: const Text('Xoa ngan quy'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _saveBudget,
                            child: Text(
                              _saving ? 'Dang luu...' : 'Luu thay doi',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: colors.primary.withValues(alpha: 0.06),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Giao dich hang muc',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Moi nhat',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: _loadingTxns
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _transactions.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Chua co giao dich trong hang muc nay',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _transactions.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final t = _transactions[index];
                                        return InkWell(
                                          onTap: () => _openTransaction(t),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: colors.onSurface
                                                  .withValues(alpha: 0.04),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: t.category.color
                                                        .withValues(
                                                          alpha: 0.22,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    t.category.icon,
                                                    size: 20,
                                                    color: t.category.color,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        t.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _formatDateTime(t.date),
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: colors
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '${t.isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: t.isIncome
                                                            ? colors.primary
                                                            : const Color(
                                                                0xFFF43F5E,
                                                              ),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
