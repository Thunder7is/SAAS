import 'attendance_record.dart';

class ImportRowError {
  final int rowIndex;
  final Map<String, dynamic> rawRowData;
  final String errorMessage;

  const ImportRowError({
    required this.rowIndex,
    required this.rawRowData,
    required this.errorMessage,
  });

  @override
  String toString() => 'Row #$rowIndex Error: $errorMessage | Data: $rawRowData';
}

class ImportResult {
  final List<AttendanceRecord> importedRecords;
  final List<ImportRowError> errors;
  final int totalRowsProcessed;
  final int successfulRows;
  final List<String> newlyCreatedSubjects;

  const ImportResult({
    required this.importedRecords,
    required this.errors,
    required this.totalRowsProcessed,
    required this.successfulRows,
    required this.newlyCreatedSubjects,
  });

  bool get hasErrors => errors.isNotEmpty;
  double get successRate =>
      totalRowsProcessed == 0 ? 0.0 : (successfulRows / totalRowsProcessed) * 100;
}
