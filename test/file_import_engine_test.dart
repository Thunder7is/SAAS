import 'package:flutter_test/flutter_test.dart';
import 'package:saas/domain/models/attendance_record.dart';
import 'package:saas/domain/models/column_mapping.dart';
import 'package:saas/domain/usecases/file_import_engine.dart';

void main() {
  group('FileImportEngine Unit Tests', () {
    test('autoGuess identifies columns correctly based on headers', () {
      final headers = ['Course Title', 'Session Date', 'Presence Status', 'Is Practical Lab'];
      final guessedMapping = ColumnMapping.autoGuess(
        collegeId: 'test_college',
        headers: headers,
      );

      expect(guessedMapping.subjectCol, equals('Course Title'));
      expect(guessedMapping.dateCol, equals('Session Date'));
      expect(guessedMapping.statusCol, equals('Presence Status'));
      expect(guessedMapping.isLabCol, equals('Is Practical Lab'));
    });

    test('processDataRows successfully parses valid rows and captures malformed rows gracefully', () {
      final headers = ['Course Name', 'Date', 'Status'];
      final rows = [
        ['Data Structures', '2026-08-01', 'Present'],
        ['Data Structures', 'INVALID_DATE_ABC', 'Present'], // Malformed row 1: bad date
        ['Mathematics', '2026-08-02', 'Absent'],
        ['', '2026-08-03', 'Present'], // Malformed row 2: missing subject
        ['Database Systems', '2026-08-04', 'UNKNOWN_STATUS_XYZ'], // Malformed row 3: bad status
        ['Database Systems', '2026-08-05', 'Medical Leave'],
      ];

      final mapping = ColumnMapping(
        collegeId: 'test_college',
        subjectCol: 'Course Name',
        dateCol: 'Date',
        statusCol: 'Status',
        updatedAt: DateTime.now(),
      );

      final Map<String, int> subjectMap = {
        'Data Structures': 1,
        'Mathematics': 2,
        'Database Systems': 3,
      };

      final result = FileImportEngine.processDataRows(
        headers: headers,
        rows: rows,
        mapping: mapping,
        subjectNameToIdMap: subjectMap,
      );

      // Verify that import did not fail entirely!
      expect(result.totalRowsProcessed, equals(6));
      expect(result.successfulRows, equals(3)); // Rows 0, 2, 5 succeeded
      expect(result.errors.length, equals(3));  // Rows 1, 3, 4 reported errors

      // Check imported valid records
      expect(result.importedRecords.length, equals(3));
      expect(result.importedRecords[0].status, equals(AttendanceStatus.present));
      expect(result.importedRecords[1].status, equals(AttendanceStatus.absent));
      expect(result.importedRecords[2].status, equals(AttendanceStatus.medicalLeave));

      // Verify row error details
      expect(result.errors[0].rowIndex, equals(3)); // row index offset
      expect(result.errors[0].errorMessage, contains('Unparseable date'));
      expect(result.errors[1].errorMessage, contains('Subject name is empty'));
      expect(result.errors[2].errorMessage, contains('Unrecognized attendance status'));
    });
  });
}
