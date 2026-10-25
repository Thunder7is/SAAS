import '../../domain/models/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/local/database_helper.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final DatabaseHelper dbHelper;

  AttendanceRepositoryImpl({DatabaseHelper? helper})
      : dbHelper = helper ?? DatabaseHelper.instance;

  @override
  Future<List<AttendanceRecord>> getRecordsBySubject(int subjectId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'attendance_records',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  @override
  Future<List<AttendanceRecord>> getAllRecords() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'attendance_records',
      orderBy: 'date DESC',
    );
    return maps.map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  @override
  Future<int> insertRecord(AttendanceRecord record) async {
    final db = await dbHelper.database;
    return await db.insert('attendance_records', record.toMap());
  }

  @override
  Future<int> updateRecord(AttendanceRecord record) async {
    final db = await dbHelper.database;
    return await db.update(
      'attendance_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<int> deleteRecord(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
