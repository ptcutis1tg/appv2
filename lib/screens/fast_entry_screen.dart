import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/transaction_repository.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:appv2/widgets/shared/segmented_toggle.dart';
import 'package:flutter/material.dart';

class FastEntryScreen extends StatefulWidget {
  const FastEntryScreen({super.key});

  @override
  State<FastEntryScreen> createState() => _FastEntryScreenState();
}

class _FastEntryScreenState extends State<FastEntryScreen> {
  int _typeIndex = 0; // 0 = expense, 1 = income
  String _amount = '0.00';
  DateTime _selectedDate = DateTime.now();
  final _txnRepo = TransactionRepository();

  void _onNumpadTap(String key) {
    setState(() {
      if (key == 'C') {
        _amount = '0.00';
      } else if (key == 'backspace') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0.00';
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == '0.00' || _amount == '0') {
          _amount = key;
        } else {
          _amount += key;
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
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

  Future<void> _saveTransaction(CategoryData category) async {
    final value = double.tryParse(_amount) ?? 0;
    if (value <= 0) return;

    final isIncome = _typeIndex == 1;
    final txn = TransactionData(
      title: isIncome ? 'Thu ${category.name}' : 'Chi ${category.name}',
      subtitle: category.name,
      amount: value,
      isIncome: isIncome,
      category: category,
      date: _selectedDate.toIso8601String(),
    );

    await _txnRepo.insertTransaction(txn);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
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
    final selectedDateLabel = _formatDate(_selectedDate);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              typeIndex: _typeIndex,
              selectedDateLabel: selectedDateLabel,
              onTypeChanged: (i) => setState(() => _typeIndex = i),
              onClose: () => Navigator.of(context).pop(),
              onPickDate: _pickDate,
            ),
            Expanded(
              child: _AmountDisplay(
                amount: _amount,
                selectedDateLabel: selectedDateLabel,
              ),
            ),
            _Numpad(onKeyTap: _onNumpadTap, colors: colors),
            _CategoryQuickSelect(
              colors: colors,
              onCategoryTap: _saveTransaction,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.typeIndex,
    required this.selectedDateLabel,
    required this.onTypeChanged,
    required this.onClose,
    required this.onPickDate,
  });

  final int typeIndex;
  final String selectedDateLabel;
  final ValueChanged<int> onTypeChanged;
  final VoidCallback onClose;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconCircleButton(icon: Icons.close, onTap: onClose),
          Column(
            children: [
              SizedBox(
                width: 192,
                child: SegmentedToggle(
                  options: const ['Expense', 'Income'],
                  selectedIndex: typeIndex,
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selectedDateLabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          IconCircleButton(icon: Icons.calendar_today, onTap: onPickDate),
        ],
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({
    required this.amount,
    required this.selectedDateLabel,
  });

  final String amount;
  final String selectedDateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '\$',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              amount,
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Ngay giao dich: $selectedDateLabel',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.primary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onKeyTap, required this.colors});

  final ValueChanged<String> onKeyTap;
  final ColorScheme colors;

  static const _keys = [
    ['7', '8', '9', '/'],
    ['4', '5', '6', '*'],
    ['1', '2', '3', '-'],
    ['.', '0', 'backspace', '+'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: _keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: row.map((key) {
                final isOperator = ['/', '*', '-', '+'].contains(key);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _NumpadKey(
                      label: key,
                      isOperator: isOperator,
                      colors: colors,
                      onTap: () => onKeyTap(key),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    required this.label,
    required this.isOperator,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool isOperator;
  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isOperator
              ? colors.primary.withValues(alpha: 0.15)
              : colors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: label == 'backspace'
            ? Icon(Icons.backspace_outlined, color: colors.onSurface, size: 22)
            : Text(
                label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOperator ? colors.primary : colors.onSurface,
                ),
              ),
      ),
    );
  }
}

class _CategoryQuickSelect extends StatelessWidget {
  const _CategoryQuickSelect({
    required this.colors,
    required this.onCategoryTap,
  });

  final ColorScheme colors;
  final ValueChanged<CategoryData> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'SELECT CATEGORY TO SAVE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
          ),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kQuickCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = kQuickCategories[index];
                return _CategoryChip(
                  icon: cat.icon,
                  label: cat.name,
                  colors: colors,
                  onTap: () => onCategoryTap(cat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 84,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.primary, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
