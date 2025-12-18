import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// sqflite 기반 관계형 로컬 데이터베이스 서비스
class SqfliteService {
  static Database? _database;
  static const String _dbName = 'library_local.db';
  static const int _dbVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        category TEXT NOT NULL,
        cachedAt INTEGER NOT NULL
      )
    ''');
  }

  static Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> query(String table) async {
    final db = await database;
    return await db.query(table);
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('books');
  }
}
