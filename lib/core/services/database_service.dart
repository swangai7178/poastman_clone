import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:wire_touch/models/collection.dart';
import 'package:wire_touch/models/project.dart';
import 'package:wire_touch/models/request_model.dart';

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
    version: 2, // 1. Bump version to 2
    onCreate: _createDB,
    onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    // 2. Add the upgrade handler
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        // This adds the column to existing version 1 databases
        await db.execute('ALTER TABLE collections ADD COLUMN parent_id TEXT');
      }
    },
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
   CREATE TABLE IF NOT EXISTS collections (
  id TEXT PRIMARY KEY,
  project_id TEXT,
  parent_id TEXT, -- Key for nested folders
  name TEXT,
  FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
);
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
  Future<List<Project>> fetchProjects() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> projectMaps = await db.query('projects');
    List<Project> projects = [];

    for (var pMap in projectMaps) {
      final colMaps = await db.query('collections', 
          where: 'project_id = ?', 
          whereArgs: [pMap['id']]);
      
      final reqMaps = await db.rawQuery('''
        SELECT requests.* FROM requests 
        INNER JOIN collections ON requests.collection_id = collections.id
        WHERE collections.project_id = ?
      ''', [pMap['id']]);

      List<Collection> allCols = colMaps.map((m) => Collection.fromMap(m)).toList();
      List<RequestModel> allReqs = reqMaps.map((m) => RequestModel.fromMap(m)).toList();

      // THE CRITICAL LINKING STEP
      for (var col in allCols) {
        col.subFolders = allCols.where((c) => c.parentId == col.id).toList();
        col.requests = allReqs.where((r) => r.id == col.id).toList();
      }

      projects.add(Project(
        id: pMap['id'],
        name: pMap['name'],
        collections: allCols, 
      ));
    }
    return projects;
  }
}