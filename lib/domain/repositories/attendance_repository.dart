import '../models/attendance_record.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getRecordsBySubject(int subjectId);
  Future<List<AttendanceRecord>> getAllRecords();
  Future<int> insertRecord(AttendanceRecord record);
  Future<int> updateRecord(AttendanceRecord record);
  Future<int> deleteRecord(int id);
}
