import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/transaction_repository.dart';
import 'package:appv2/screens/transaction_detail_screen.dart';
import 'package:appv2/widgets/shared/icon_circle_button.dart';
import 'package:appv2/widgets/shared/transaction_item.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key, required this.transactions});

  final List<TransactionData> transactions;

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _txnRepo = TransactionRepository();
  late List<TransactionData> _transactions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transactions = [...widget.transactions];
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final latest = await _txnRepo.getAllTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = latest;
      _isLoading = false;
    });
  }

  Future<void> _openDetails(TransactionData transaction) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: transaction),
      ),
    );
    if (changed == true && mounted) {
      _reload();
    }
  }

  DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
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
    final sorted = [..._transactions]
      ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

    final grouped = <String, List<TransactionData>>{};
    for (final t in sorted) {
      final key = _formatDate(_parseDate(t.date));
      grouped.putIfAbsent(key, () => <TransactionData>[]).add(t);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                children: [
                  IconCircleButton(
                    icon: Icons.chevron_left,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lich su giao dich',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                  ? Center(
                      child: Text(
                        'Chua co giao dich nao',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: const {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.invertedStylus,
                          PointerDeviceKind.unknown,
                        },
                      ),
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        children: [
                          ...grouped.entries.expand(
                            (entry) => [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 10,
                                ),
                                child: Text(
                                  entry.key,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...entry.value.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TransactionItem(
                                    icon: t.category.icon,
                                    iconBackgroundColor: t.category.color,
                                    iconColor: t.category.color,
                                    title: t.title,
                                    subtitle: t.subtitle,
                                    amount: t.isIncome
                                        ? '+\$${t.amount.toStringAsFixed(2)}'
                                        : '-\$${t.amount.toStringAsFixed(2)}',
                                    isIncome: t.isIncome,
                                    onTap: () => _openDetails(t),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
