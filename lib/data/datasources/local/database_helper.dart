import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('saas_attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. subjects (id, name, college_id)
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        college_id TEXT NOT NULL
      )
    ''');

    // 2. attendance_records (id, subject_id, date, status, is_lab, source)
    await db.execute('''
      CREATE TABLE attendance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        is_lab INTEGER NOT NULL DEFAULT 0,
        source TEXT NOT NULL DEFAULT 'manual',
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // 3. rule_configs (college_id, threshold_pct, calculation_mode, excluded_statuses, lab_weight_multiplier, per_subject_weighting)
    await db.execute('''
      CREATE TABLE rule_configs (
        college_id TEXT PRIMARY KEY,
        threshold_pct REAL NOT NULL,
        calculation_mode TEXT NOT NULL,
        excluded_statuses TEXT,
        lab_weight_multiplier REAL NOT NULL DEFAULT 1.0,
        per_subject_weighting TEXT
      )
    ''');

    // 4. column_mappings (college_id, subject_col, date_col, status_col, is_lab_col, updated_at)
    await db.execute('''
      CREATE TABLE column_mappings (
        college_id TEXT PRIMARY KEY,
        subject_col TEXT NOT NULL,
        date_col TEXT NOT NULL,
        status_col TEXT NOT NULL,
        is_lab_col TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // 5. timetable_entries (id, subject_id, subject_name, day_of_week, start_time, end_time, room, is_lab)
    await db.execute('''
      CREATE TABLE timetable_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        subject_name TEXT NOT NULL,
        day_of_week TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        room TEXT NOT NULL,
        is_lab INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
