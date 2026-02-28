import 'dart:math';

import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/category_repository.dart';
import 'package:appv2/db/transaction_repository.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final TransactionData transaction;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  final _txnRepo = TransactionRepository();
  final _categoryRepo = CategoryRepository();
  final _rng = Random();
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

  List<CategoryData> _categories = [];
  CategoryData? _selectedCategory;
  late DateTime _selectedDate;
  late bool _isIncome;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final txn = widget.transaction;
    _titleController.text = txn.title;
    _noteController.text = txn.subtitle;
    _amountController.text = txn.amount.toStringAsFixed(2);
    _isIncome = txn.isIncome;
    _selectedDate = DateTime.tryParse(txn.date ?? '') ?? DateTime.now();
    _selectedCategory = txn.category;
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final dbCategories = await _categoryRepo.getAllCategories();
    if (!mounted) return;

    final current = widget.transaction.category;
    final merged = <CategoryData>[
      ...dbCategories,
      ...kQuickCategories.where(
        (quick) => !dbCategories.any((db) => db.id == quick.id),
      ),
    ];

    if (!merged.any((c) => c.id == current.id && c.name == current.name)) {
      merged.insert(0, current);
    }

    setState(() {
      _categories = merged;
      _selectedCategory ??= merged.isNotEmpty ? merged.first : current;
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 15),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    final category = _selectedCategory;
    if (amount == null || amount <= 0 || category == null) return;
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    final updated = TransactionData(
      id: widget.transaction.id,
      title: _titleController.text.trim(),
      subtitle: _noteController.text.trim(),
      amount: amount,
      isIncome: _isIncome,
      category: category,
      date: _selectedDate.toIso8601String(),
    );

    await _txnRepo.updateTransaction(updated);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _applyRandomColor() {
    final selected = _selectedCategory;
    if (selected == null) return;
    final color = _colorChoices[_rng.nextInt(_colorChoices.length)];
    _updateSelectedCategoryColor(color);
  }

  void _updateSelectedCategoryColor(Color color) {
    final selected = _selectedCategory;
    if (selected == null) return;
    setState(() {
      _selectedCategory = CategoryData(
        id: selected.id,
        name: selected.name,
        icon: selected.icon,
        color: color,
      );
      _categories = _categories
          .map(
            (c) => c.id == selected.id
                ? CategoryData(
                    id: c.id,
                    name: c.name,
                    icon: c.icon,
                    color: color,
                  )
                : c,
          )
          .toList();
    });
  }

  Future<void> _delete() async {
    final id = widget.transaction.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa giao dich'),
        content: const Text('Ban co chac chan muon xoa giao dich nay?'),
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
    setState(() => _isDeleting = true);
    await _txnRepo.deleteTransaction(id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconCircleButton(
                          icon: Icons.chevron_left,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chi tiet giao dich',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChip(
                            label: 'Chi tieu',
                            active: !_isIncome,
                            onTap: () => setState(() => _isIncome = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeChip(
                            label: 'Thu nhap',
                            active: _isIncome,
                            onTap: () => setState(() => _isIncome = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tieu de',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'So tien',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.onSurface.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(_selectedDate),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Danh muc', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._colorChoices.map(
                          (c) => InkWell(
                            onTap: () => _updateSelectedCategoryColor(c),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedCategory?.color == c
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _applyRandomColor,
                          icon: const Icon(Icons.shuffle),
                          label: const Text('Ngau nhien'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final active =
                              _selectedCategory?.id == cat.id &&
                              _selectedCategory?.name == cat.name;
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 84,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: active
                                    ? colors.primary.withValues(alpha: 0.16)
                                    : colors.onSurface.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: active
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
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving || _isDeleting ? null : _save,
                        child: Text(_isSaving ? 'Dang luu...' : 'Luu thay doi'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSaving || _isDeleting ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                        ),
                        child: Text(
                          _isDeleting ? 'Dang xoa...' : 'Xoa giao dich',
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active ? colors.primary.withValues(alpha: 0.2) : null,
          border: Border.all(
            color: active
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.15),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
