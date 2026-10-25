import 'package:sqflite/sqflite.dart';
import '../../domain/models/timetable_entry.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../datasources/local/database_helper.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  final DatabaseHelper dbHelper;

  TimetableRepositoryImpl({DatabaseHelper? helper})
      : dbHelper = helper ?? DatabaseHelper.instance;

  @override
  Future<List<TimetableEntry>> getAllEntries() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'timetable_entries',
      orderBy: 'day_of_week ASC, start_time ASC',
    );
    return maps.map((m) => TimetableEntry.fromMap(m)).toList();
  }

  @override
  Future<List<TimetableEntry>> getEntriesByDay(String dayOfWeek) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'timetable_entries',
      where: 'LOWER(day_of_week) = ?',
      whereArgs: [dayOfWeek.toLowerCase()],
      orderBy: 'start_time ASC',
    );
    return maps.map((m) => TimetableEntry.fromMap(m)).toList();
  }

  @override
  Future<int> insertEntry(TimetableEntry entry) async {
    final db = await dbHelper.database;
    return await db.insert('timetable_entries', entry.toMap());
  }

  @override
  Future<int> updateEntry(TimetableEntry entry) async {
    final db = await dbHelper.database;
    return await db.update(
      'timetable_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  @override
  Future<int> deleteEntry(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'timetable_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAll() async {
    final db = await dbHelper.database;
    await db.delete('timetable_entries');
  }
}
