import 'package:appv2/data/mock_data.dart';
import 'package:appv2/db/database_helper.dart';

class UserRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<UserProfileData?> getUser() async {
    final db = await dbHelper.database;
    final maps = await db.query('users', limit: 1);
    if (maps.isNotEmpty) {
      return UserProfileData.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(UserProfileData user) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
