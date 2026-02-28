import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class TransactionRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> _upsertCategory(Database db, CategoryData category) async {
    if (category.id != null) {
      final id = category.id!;
      final exists = await db.query(
        'categories',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (exists.isNotEmpty) {
        await db.update(
          'categories',
          {
            'name': category.name,
            'icon_code': category.icon.codePoint,
            'color_hex': category.color.value.toRadixString(16).padLeft(8, '0'),
            'is_default': 0,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        return id;
      }

      await db.insert('categories', {...category.toMap(), 'is_default': 0});
      return id;
    }

    return db.insert('categories', {...category.toMap(), 'is_default': 0});
  }

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
        amount: (map['amount'] as num).toDouble(),
        isIncome: (map['is_income'] as int) == 1,
        date: map['date'] as String?,
        category: category,
      );
    }).toList();
  }

  Future<List<TransactionData>> getTransactionsByCategory(
    int categoryId,
  ) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT t.*, c.id as c_id, c.name as c_name, c.icon_code as c_icon_code, c.color_hex as c_color_hex
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE t.category_id = ?
      ORDER BY datetime(t.date) DESC, t.id DESC
      ''',
      [categoryId],
    );

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
        amount: (map['amount'] as num).toDouble(),
        isIncome: (map['is_income'] as int) == 1,
        date: map['date'] as String?,
        category: category,
      );
    }).toList();
  }

  Future<int> insertTransaction(TransactionData transaction) async {
    final db = await dbHelper.database;
    final categoryId = await _upsertCategory(db, transaction.category);

    final map = transaction.toMap();
    map['category_id'] = categoryId;
    return await db.insert('transactions', map);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await dbHelper.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTransaction(TransactionData transaction) async {
    final db = await dbHelper.database;
    final txnId = transaction.id;
    if (txnId == null) return 0;
    final categoryId = await _upsertCategory(db, transaction.category);

    final map = transaction.toMap();
    map.remove('id');
    map['category_id'] = categoryId;

    return db.update('transactions', map, where: 'id = ?', whereArgs: [txnId]);
  }
}
