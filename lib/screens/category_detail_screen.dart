import 'dart:math';

import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/category_repository.dart';
import 'package:appv2/db/transaction_repository.dart';
import 'package:appv2/screens/transaction_detail_screen.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:flutter/material.dart';

class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final int categoryId;

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final _repo = CategoryRepository();
  final _txnRepo = TransactionRepository();
  final _nameController = TextEditingController();
  final _rng = Random();

  static const _iconChoices = <IconData>[
    Icons.restaurant,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.receipt_long,
    Icons.payments,
    Icons.movie,
    Icons.local_hospital,
    Icons.school,
    Icons.sports_esports,
    Icons.pets,
    Icons.coffee,
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

  CategoryData? _category;
  IconData _selectedIcon = Icons.star;
  Color _selectedColor = const Color(0xFF13EC5B);
  List<TransactionData> _transactions = [];
  bool _loading = true;
  bool _loadingTransactions = true;
  bool _saving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final category = await _repo.getCategoryById(widget.categoryId);
    if (!mounted) return;
    if (category == null) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _category = category;
      _nameController.text = category.name;
      _selectedIcon = category.icon;
      _selectedColor = category.color;
      _loading = false;
    });
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loadingTransactions = true);
    final transactions = await _txnRepo.getTransactionsByCategory(
      widget.categoryId,
    );
    if (!mounted) return;
    setState(() {
      _transactions = transactions;
      _loadingTransactions = false;
    });
  }

  Future<void> _save() async {
    final current = _category;
    if (current == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    await _repo.updateCategory(
      CategoryData(
        id: current.id,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _openTransactionDetail(TransactionData transaction) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: transaction),
      ),
    );
    if (changed == true && mounted) {
      _hasChanges = true;
      _loadTransactions();
    }
  }

  void _randomColor() {
    setState(() {
      _selectedColor = _colorChoices[_rng.nextInt(_colorChoices.length)];
    });
  }

  String _formatDateTime(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return '--/--/---- --:--';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  void _close() {
    Navigator.of(context).pop(_hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
                            'Chi tiet danh muc',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Ten danh muc',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text('Icon', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _iconChoices
                                  .map(
                                    (icon) => InkWell(
                                      onTap: () =>
                                          setState(() => _selectedIcon = icon),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: _selectedIcon == icon
                                              ? colors.primary.withValues(
                                                  alpha: 0.18,
                                                )
                                              : colors.onSurface.withValues(
                                                  alpha: 0.06,
                                                ),
                                          border: Border.all(
                                            color: _selectedIcon == icon
                                                ? colors.primary
                                                : colors.onSurface.withValues(
                                                    alpha: 0.12,
                                                  ),
                                          ),
                                        ),
                                        child: Icon(
                                          icon,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            Text('Mau', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._colorChoices.map(
                                  (c) => InkWell(
                                    onTap: () =>
                                        setState(() => _selectedColor = c),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _selectedColor == c
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _randomColor,
                                  icon: const Icon(Icons.shuffle),
                                  label: const Text(
                                    'Ngau nhien',
                                    style: TextStyle(letterSpacing: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _saving ? null : _save,
                                child: Text(
                                  _saving ? 'Dang luu...' : 'Luu thay doi',
                                  style: const TextStyle(letterSpacing: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 520,
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
                                'Chi tiet hang muc',
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
                            child: _loadingTransactions
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
                                        onTap: () => _openTransactionDetail(t),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: colors.onSurface.withValues(
                                              alpha: 0.04,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: t.category.color
                                                      .withValues(alpha: 0.22),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      t.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
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
                  ],
                ),
              ),
      ),
    );
  }
}
