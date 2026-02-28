import 'package:flutter/material.dart';

// ── Category Model ───────────────────────────────────────────────────
class CategoryData {
  const CategoryData({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final int? id;
  final String name;
  final IconData icon;
  final Color color;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon_code': icon.codePoint,
    'color_hex': color.value.toRadixString(16).padLeft(8, '0'),
  };

  factory CategoryData.fromMap(Map<String, dynamic> map) {
    return CategoryData(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: IconData(map['icon_code'] as int, fontFamily: 'MaterialIcons'),
      color: Color(int.parse(map['color_hex'] as String, radix: 16)),
    );
  }
}

// ── Transaction Model ────────────────────────────────────────────────
class TransactionData {
  const TransactionData({
    this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.category,
    this.date,
  });

  final int? id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final CategoryData category;
  final String? date;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'is_income': isIncome ? 1 : 0,
    'category_id': category.id,
    'note': subtitle,
    'date': date ?? DateTime.now().toIso8601String(),
  };
}

// ── Budget Item Model ────────────────────────────────────────────────
class BudgetItemData {
  const BudgetItemData({
    this.id,
    this.categoryId,
    required this.name,
    required this.icon,
    required this.spent,
    required this.budget,
    required this.progressColor,
    this.remainingLabel,
  });

  final int? id;
  final int? categoryId;
  final String name;
  final IconData icon;
  final double spent;
  final double budget;
  final Color progressColor;
  final String? remainingLabel;

  double get percentage => (spent / budget * 100).clamp(0, 200);
  bool get isOverBudget => spent > budget;

  Map<String, dynamic> toMap(String month) => {
    'id': id,
    'category_id': categoryId,
    'budget': budget,
    'month': month,
  };
}

// ── Statistics Category Model ────────────────────────────────────────
class StatsCategoryData {
  const StatsCategoryData({
    this.categoryId,
    required this.name,
    required this.icon,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  final int? categoryId;
  final String name;
  final IconData icon;
  final double amount;
  final double percentage;
  final Color color;
}

// ── User Profile Model ──────────────────────────────────────────────
class UserProfileData {
  const UserProfileData({
    this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.badge,
    this.currency = 'VND',
  });

  final int? id;
  final String name;
  final String email;
  final String avatarUrl;
  final String? badge;
  final String currency;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar_url': avatarUrl,
    'badge': badge,
    'currency': currency,
  };

  factory UserProfileData.fromMap(Map<String, dynamic> map) {
    return UserProfileData(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatar_url'] as String,
      badge: map['badge'] as String?,
      currency: map['currency'] as String? ?? 'VND',
    );
  }
}

// ── Bottom Nav Item Model ────────────────────────────────────────────
class NavItemData {
  const NavItemData({required this.icon, required this.label, this.filledIcon});

  final IconData icon;
  final String label;
  final IconData? filledIcon;
}

// ═══════════════════════════════════════════════════════════════════════
// MOCK DATA INSTANCES
// ═══════════════════════════════════════════════════════════════════════

// ── Categories (Fast Entry) ──────────────────────────────────────────
const kQuickCategories = <CategoryData>[
  CategoryData(
    id: 1,
    name: 'Food',
    icon: Icons.restaurant,
    color: Color(0xFF13EC5B),
  ),
  CategoryData(
    id: 2,
    name: 'Travel',
    icon: Icons.directions_car,
    color: Color(0xFF13EC5B),
  ),
  CategoryData(
    id: 3,
    name: 'Shop',
    icon: Icons.shopping_bag,
    color: Color(0xFF13EC5B),
  ),
  CategoryData(
    id: 4,
    name: 'Bills',
    icon: Icons.receipt_long,
    color: Color(0xFF13EC5B),
  ),
  CategoryData(
    id: 5,
    name: 'Salary',
    icon: Icons.payments,
    color: Color(0xFF13EC5B),
  ),
  CategoryData(
    id: 6,
    name: 'Other',
    icon: Icons.grid_view,
    color: Color(0xFF13EC5B),
  ),
];

// ── Transactions (Ledger Home) ───────────────────────────────────────
final kTodayTransactions = <TransactionData>[
  const TransactionData(
    id: 1,
    title: 'Ăn trưa',
    subtitle: 'Ăn uống',
    amount: 25.00,
    isIncome: false,
    category: CategoryData(
      id: 101,
      name: 'Ăn uống',
      icon: Icons.restaurant,
      color: Color(0xFFF97316), // orange-500
    ),
  ),
  const TransactionData(
    id: 2,
    title: 'Lương tháng 5',
    subtitle: 'Thu nhập',
    amount: 3200.00,
    isIncome: true,
    category: CategoryData(
      id: 102,
      name: 'Thu nhập',
      icon: Icons.payments,
      color: Color(0xFF13EC5B),
    ),
  ),
  const TransactionData(
    id: 3,
    title: 'Xăng xe',
    subtitle: 'Di chuyển',
    amount: 15.50,
    isIncome: false,
    category: CategoryData(
      id: 103,
      name: 'Di chuyển',
      icon: Icons.directions_car,
      color: Color(0xFF3B82F6), // blue-500
    ),
  ),
];

final kYesterdayTransactions = <TransactionData>[
  const TransactionData(
    id: 4,
    title: 'Quần áo mới',
    subtitle: 'Mua sắm',
    amount: 120.00,
    isIncome: false,
    category: CategoryData(
      id: 104,
      name: 'Mua sắm',
      icon: Icons.shopping_bag,
      color: Color(0xFF8B5CF6), // purple-500
    ),
  ),
];

// ── Budget Items ─────────────────────────────────────────────────────
const kBudgetItems = <BudgetItemData>[
  BudgetItemData(
    id: 1,
    categoryId: 101,
    name: 'Ăn uống',
    icon: Icons.restaurant,
    spent: 4800000,
    budget: 6000000,
    progressColor: Color(0xFF13EC5B),
    remainingLabel: 'Còn lại 1.200.000đ',
  ),
  BudgetItemData(
    id: 2,
    categoryId: 104,
    name: 'Mua sắm',
    icon: Icons.shopping_bag,
    spent: 2850000,
    budget: 3000000,
    progressColor: Color(0xFFEAB308), // yellow-500
    remainingLabel: 'Còn lại 150.000đ',
  ),
  BudgetItemData(
    id: 3,
    categoryId: 103,
    name: 'Di chuyển',
    icon: Icons.directions_car,
    spent: 2250000,
    budget: 2000000,
    progressColor: Color(0xFFEF4444), // red-500
    remainingLabel: 'Vượt 250.000đ',
  ),
  BudgetItemData(
    id: 4,
    categoryId: 105,
    name: 'Giải trí',
    icon: Icons.movie,
    spent: 500000,
    budget: 1500000,
    progressColor: Color(0xFF13EC5B),
    remainingLabel: 'Còn lại 1.000.000đ',
  ),
];

// ── Statistics Categories ────────────────────────────────────────────
const kStatsCategories = <StatsCategoryData>[
  StatsCategoryData(
    name: 'Ăn uống',
    icon: Icons.restaurant,
    amount: 558.20,
    percentage: 45,
    color: Color(0xFF13EC5B),
  ),
  StatsCategoryData(
    name: 'Mua sắm',
    icon: Icons.shopping_bag,
    amount: 372.15,
    percentage: 30,
    color: Color(0xFF0EBE49), // primary/60
  ),
  StatsCategoryData(
    name: 'Di chuyển',
    icon: Icons.directions_car,
    amount: 186.08,
    percentage: 15,
    color: Color(0xFF0A8E37), // primary/40
  ),
];

// ── User (Settings) ──────────────────────────────────────────────────
const kUserProfile = UserProfileData(
  id: 1,
  name: 'Minh Tuấn',
  email: 'tuan.minh@finance.vn',
  avatarUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBlV3u4jpyveFN4V6mq8Urqe_prTQs84FXN5Xwecs-6Yal904du8GQ5zgh7XCc-d8KF4g8KNhY1MLZV-0bMAZO58h_2MALrAQqAZ_Fy967LtGEg42qNo8iMbg0ntJh_wS0LM1C1CVh6ZqppgYlmICu_D8MXGDQyqUoIWpLphm-E8_TPZbRJsFQQjaP3awLdrGKr4oCqFtszRKYXArn0cgKKLik4M5aw7Rv2nQtpXg6SifWRobePwNOCJ2a6NtgF-P08Gt_PcqLm7wU',
  badge: 'Premium Member',
);

// ── Ledger Balance ───────────────────────────────────────────────────
List<TransactionData> get kAllTransactions => [
  ...kTodayTransactions,
  ...kYesterdayTransactions,
];

double _sumTransactions(Iterable<TransactionData> transactions, bool isIncome) {
  return transactions
      .where((t) => t.isIncome == isIncome)
      .fold<double>(0, (sum, t) => sum + t.amount);
}

String _formatChange(double todayValue, double yesterdayValue) {
  if (yesterdayValue == 0) {
    if (todayValue == 0) return '0%';
    return '+100%';
  }

  final percent = ((todayValue - yesterdayValue) / yesterdayValue) * 100;
  final sign = percent >= 0 ? '+' : '';
  return '$sign${percent.toStringAsFixed(0)}%';
}

double get kIncome => _sumTransactions(kAllTransactions, true);
double get kExpense => _sumTransactions(kAllTransactions, false);
double get kBalance => kIncome - kExpense;
String get kIncomeChange => _formatChange(
  _sumTransactions(kTodayTransactions, true),
  _sumTransactions(kYesterdayTransactions, true),
);
String get kExpenseChange => _formatChange(
  _sumTransactions(kTodayTransactions, false),
  _sumTransactions(kYesterdayTransactions, false),
);

void addTransaction({
  required String title,
  required String subtitle,
  required double amount,
  required bool isIncome,
  required CategoryData category,
}) {
  kTodayTransactions.insert(
    0,
    TransactionData(
      title: title,
      subtitle: subtitle,
      amount: amount,
      isIncome: isIncome,
      category: category,
      date: DateTime.now().toIso8601String(),
    ),
  );
}

// ── Budget Summary ───────────────────────────────────────────────────
const kTotalBudget = '24.500.000đ';
const kBudgetRemaining = 'Còn lại 8.200.000đ';
const kBudgetUsedPercent = 66;
const kBudgetMonth = 'Tháng 10, 2023';

// ── Statistics Summary ───────────────────────────────────────────────
const kTotalSpending = 1240.50;
