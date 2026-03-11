import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wire_touch.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE requests (
        id TEXT PRIMARY KEY,
        collection_id TEXT NOT NULL,
        name TEXT NOT NULL,
        method TEXT NOT NULL,
        url TEXT NOT NULL,
        body TEXT,
        headers TEXT,
        query_params TEXT,
        FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE CASCADE
      )
    ''');
  }
}