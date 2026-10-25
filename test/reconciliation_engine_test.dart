import 'package:flutter_test/flutter_test.dart';
import 'package:saas/domain/models/attendance_record.dart';
import 'package:saas/domain/usecases/reconciliation_engine.dart';

void main() {
  group('ReconciliationEngine Unit Tests', () {
    final Map<int, String> subjectMap = {
      1: 'Data Structures',
      2: 'Database Systems',
    };

    final DateTime today = DateTime(2026, 8, 4);
    final DateTime yesterday = DateTime(2026, 8, 3);

    test('Auto-merges manual record when imported status matches manual entry', () {
      final existingRecords = [
        AttendanceRecord(
          id: 10,
          subjectId: 1,
          date: today,
          status: AttendanceStatus.present,
          source: RecordSource.manual, // Marked manually today
        ),
      ];

      final incomingRecords = [
        AttendanceRecord(
          subjectId: 1,
          date: today,
          status: AttendanceStatus.present, // Official sheet confirms Present
          source: RecordSource.imported,
        ),
      ];

      final result = ReconciliationEngine.reconcile(
        existingRecords: existingRecords,
        incomingRecords: incomingRecords,
        subjectIdToNameMap: subjectMap,
      );

      expect(result.conflicts, isEmpty);
      expect(result.autoMergedCount, equals(1));
      expect(result.recordsToSave.first.source, equals(RecordSource.imported));
    });

    test('Detects conflict when manual entry disagrees with official imported sheet', () {
      final existingRecords = [
        AttendanceRecord(
          id: 11,
          subjectId: 1,
          date: today,
          status: AttendanceStatus.present,
          source: RecordSource.manual, // Student marked Present manually
        ),
      ];

      final incomingRecords = [
        AttendanceRecord(
          subjectId: 1,
          date: today,
          status: AttendanceStatus.absent, // Official sheet says ABSENT!
          source: RecordSource.imported,
        ),
      ];

      final result = ReconciliationEngine.reconcile(
        existingRecords: existingRecords,
        incomingRecords: incomingRecords,
        subjectIdToNameMap: subjectMap,
      );

      expect(result.conflicts.length, equals(1));
      final conflict = result.conflicts.first;

      expect(conflict.subjectName, equals('Data Structures'));
      expect(conflict.existingManualRecord.status, equals(AttendanceStatus.present));
      expect(conflict.incomingImportedRecord.status, equals(AttendanceStatus.absent));
    });

    test('Inserts new records and updates existing imported records without conflict', () {
      final existingRecords = [
        AttendanceRecord(
          id: 12,
          subjectId: 2,
          date: yesterday,
          status: AttendanceStatus.absent,
          source: RecordSource.imported,
        ),
      ];

      final incomingRecords = [
        AttendanceRecord(
          subjectId: 2,
          date: yesterday,
          status: AttendanceStatus.medicalLeave, // Rectified in official sheet
          source: RecordSource.imported,
        ),
        AttendanceRecord(
          subjectId: 2,
          date: today,
          status: AttendanceStatus.present,
          source: RecordSource.imported,
        ),
      ];

      final result = ReconciliationEngine.reconcile(
        existingRecords: existingRecords,
        incomingRecords: incomingRecords,
        subjectIdToNameMap: subjectMap,
      );

      expect(result.conflicts, isEmpty);
      expect(result.newInsertedCount, equals(1));
      expect(result.recordsToSave.length, equals(2));
    });
  });
}
