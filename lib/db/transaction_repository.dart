import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class TransactionRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<TransactionData>> getAllTransactions() async {
    final db = await dbHelper.database;

    // Perform a JOIN to get category data
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, c.id as c_id, c.name as c_name, c.icon_code as c_icon_code, c.color_hex as c_color_hex
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      ORDER BY date(t.date) DESC, t.id DESC
    ''');

    return maps.map((map) {
      final category = CategoryData(
        id: map['c_id'] as int?,
        name: map['c_name'] as String,
        icon: IconData(map['c_icon_code'] as int, fontFamily: 'MaterialIcons'),
        color: Color(int.parse(map['c_color_hex'] as String, radix: 16)),
      );

      return TransactionData(
        id: map['id'] as int?,
        title: map['title'] as String,
        subtitle: map['note'] as String? ?? '',
        amount: map['amount'] as double,
        isIncome: (map['is_income'] as int) == 1,
        date: map['date'] as String?,
        category: category,
      );
    }).toList();
  }

  Future<int> insertTransaction(TransactionData transaction) async {
    final db = await dbHelper.database;
    final category = transaction.category;

    if (category.id != null) {
      await db.insert('categories', {
        ...category.toMap(),
        'is_default': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> deleteTransaction(int id) async {
    final db = await dbHelper.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
