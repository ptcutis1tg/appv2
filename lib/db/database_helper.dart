import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE users (
  id $idType,
  name $textType,
  email $textType,
  avatar_url $textNullable,
  badge $textNullable,
  currency TEXT DEFAULT 'VND',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  icon_code $intType,
  color_hex $textType,
  is_default INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  title $textType,
  amount $realType,
  is_income $intType,
  category_id $intType,
  note $textNullable,
  date $textType,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories (id)
)
''');

    await db.execute('''
CREATE TABLE budgets (
  id $idType,
  category_id $intType,
  budget $realType,
  month $textType,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories (id)
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
