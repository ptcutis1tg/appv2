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
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalendarPickerSheet(initialDate: _selectedDate),
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

class _CalendarPickerSheet extends StatefulWidget {
  const _CalendarPickerSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_CalendarPickerSheet> createState() => _CalendarPickerSheetState();
}

class _CalendarPickerSheetState extends State<_CalendarPickerSheet> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  bool _showYearPicker = false;

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _monthNames = [
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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _goPrevMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _goNextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _toggleYearPicker() {
    setState(() {
      _showYearPicker = !_showYearPicker;
    });
  }

  void _selectYear(int year) {
    setState(() {
      _displayedMonth = DateTime(year, _displayedMonth.month, 1);
      if (_selectedDate.year != year) {
        final maxDayInMonth = DateTime(year, _selectedDate.month + 1, 0).day;
        final safeDay = _selectedDate.day > maxDayInMonth ? maxDayInMonth : _selectedDate.day;
        _selectedDate = DateTime(
          year,
          _selectedDate.month,
          safeDay,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      }
      _showYearPicker = false;
    });
  }

  List<int> _yearOptions() {
    final centerYear = _displayedMonth.year;
    return List.generate(61, (i) => centerYear - 30 + i);
  }

  List<DateTime> _visibleDatesForMonth(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final firstGridDate = firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
    return List.generate(42, (i) => firstGridDate.add(Duration(days: i)));
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dates = _visibleDatesForMonth(_displayedMonth);
    final monthLabel = _monthNames[_displayedMonth.month - 1];
    final yearLabel = '${_displayedMonth.year}';
    final years = _yearOptions();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF070B11),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        Text(
                          monthLabel,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _toggleYearPicker,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  yearLabel,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(
                                  _showYearPicker
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: const Color(0xFF90A2C3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!_showYearPicker) ...[
                      IconButton(
                        onPressed: _goPrevMonth,
                        icon: const Icon(Icons.chevron_left, color: Color(0xFF90A2C3)),
                      ),
                      IconButton(
                        onPressed: _goNextMonth,
                        icon: const Icon(Icons.chevron_right, color: Color(0xFF90A2C3)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _showYearPicker
                      ? SizedBox(
                          key: const ValueKey('year-grid'),
                          height: 320,
                          child: GridView.builder(
                            itemCount: years.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisExtent: 56,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemBuilder: (context, index) {
                              final year = years[index];
                              final isCurrent = year == _displayedMonth.year;
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _selectYear(year),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? colors.primary.withValues(alpha: 0.18)
                                        : const Color(0xFF111821),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isCurrent
                                          ? colors.primary
                                          : const Color(0xFF1E2A3A),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$year',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent
                                          ? colors.primary
                                          : const Color(0xFFD3DCE9),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Column(
                          key: const ValueKey('day-grid'),
                          children: [
                            Row(
                              children: _weekdays
                                  .map(
                                    (d) => Expanded(
                                      child: Center(
                                        child: Text(
                                          d,
                                          style: const TextStyle(
                                            color: Color(0xFF6F7F99),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dates.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisExtent: 46,
                              ),
                              itemBuilder: (context, index) {
                                final day = dates[index];
                                final inMonth = day.month == _displayedMonth.month;
                                final isSelected = _isSameDate(day, _selectedDate);

                                return Center(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(22),
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = day;
                                      });
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colors.primary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF07100A)
                                              : (inMonth
                                                  ? Colors.white
                                                  : const Color(0xFF344760)),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFF1A2534),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: const Color(0xFF07100A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(_selectedDate),
                    child: const Text(
                      'XAC NHAN',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
