import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/database_helper.dart';
import 'package:flutter/material.dart';

class BudgetRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<BudgetItemData>> getBudgetsByMonth(String month) async {
    final db = await dbHelper.database;

    // We also need spent amount. Let's calculate from transactions for this month.
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT b.id, b.budget, b.category_id, 
             c.name as c_name, c.icon_code as c_icon_code, c.color_hex as c_color_hex,
             COALESCE(SUM(t.amount), 0) as spent
      FROM budgets b
      INNER JOIN categories c ON b.category_id = c.id
      LEFT JOIN transactions t ON t.category_id = b.category_id AND t.is_income = 0 AND strftime('%Y-%m', t.date) = ?
      WHERE b.month = ?
      GROUP BY b.id
    ''',
      [month, month],
    );

    return maps.map((map) {
      final spent = (map['spent'] as num?)?.toDouble() ?? 0.0;
      final budget = (map['budget'] as num?)?.toDouble() ?? 0.0;
      return BudgetItemData(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int?,
        name: map['c_name'] as String,
        icon: IconData(map['c_icon_code'] as int, fontFamily: 'MaterialIcons'),
        spent: spent,
        budget: budget,
        progressColor: const Color(0xFF13EC5B),
      );
    }).toList();
  }

  Future<int> upsertBudget(int categoryId, double budget, String month) async {
    final db = await dbHelper.database;
    final existing = await db.query(
      'budgets',
      where: 'category_id = ? AND month = ?',
      whereArgs: [categoryId, month],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'budgets',
        {'budget': budget},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('budgets', {
        'category_id': categoryId,
        'budget': budget,
        'month': month,
      });
    }
  }

  Future<int> deleteBudget(int categoryId, String month) async {
    final db = await dbHelper.database;
    return db.delete(
      'budgets',
      where: 'category_id = ? AND month = ?',
      whereArgs: [categoryId, month],
    );
  }
}
