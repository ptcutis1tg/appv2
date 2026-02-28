import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/database_helper.dart';

class CategoryRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<CategoryData>> getAllCategories() async {
    final db = await dbHelper.database;
    final maps = await db.query('categories');
    return maps.map((map) => CategoryData.fromMap(map)).toList();
  }

  Future<int> insertCategory(CategoryData category) async {
    final db = await dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  Future<CategoryData?> getCategoryById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return CategoryData.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(CategoryData category) async {
    final db = await dbHelper.database;
    final id = category.id;
    if (id == null) return 0;
    final map = category.toMap()..remove('id');
    return db.update('categories', map, where: 'id = ?', whereArgs: [id]);
  }
}
