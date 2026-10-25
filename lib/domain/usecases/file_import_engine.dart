import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/attendance_record.dart';
import '../models/column_mapping.dart';
import '../models/import_result.dart';

class FileImportEngine {
  /// Parse CSV raw string into header list and row grid
  static Map<String, dynamic> parseCsv(String csvText) {
    final constConverter = CsvToListConverter(shouldParseNumbers: false);
    final List<List<dynamic>> rows = constConverter.convert(csvText);

    if (rows.isEmpty) {
      return {'headers': <String>[], 'rows': <List<dynamic>>[]};
    }

    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.sublist(1);

    return {'headers': headers, 'rows': dataRows};
  }

  /// Parse Excel binary bytes into header list and row grid
  static Map<String, dynamic> parseExcel(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return {'headers': <String>[], 'rows': <List<dynamic>>[]};
    }

    final defaultSheetName = excel.tables.keys.first;
    final table = excel.tables[defaultSheetName];
    if (table == null || table.rows.isEmpty) {
      return {'headers': <String>[], 'rows': <List<dynamic>>[]};
    }

    final rawHeaders = table.rows.first;
    final headers = rawHeaders.map((cell) => cell?.value?.toString().trim() ?? '').toList();

    final dataRows = table.rows.sublist(1).map((row) {
      return row.map((cell) => cell?.value?.toString() ?? '').toList();
    }).toList();

    return {'headers': headers, 'rows': dataRows};
  }

  /// Map arbitrary data rows to AttendanceRecord schema based on ColumnMapping
  static ImportResult processDataRows({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required ColumnMapping mapping,
    required Map<String, int> subjectNameToIdMap,
  }) {
    final List<AttendanceRecord> records = [];
    final List<ImportRowError> errors = [];
    final List<String> newSubjects = [];

    int subjectIdx = headers.indexOf(mapping.subjectCol);
    int dateIdx = headers.indexOf(mapping.dateCol);
    int statusIdx = headers.indexOf(mapping.statusCol);
    int isLabIdx = mapping.isLabCol != null ? headers.indexOf(mapping.isLabCol!) : -1;

    // Fallback search if exact string match fails
    if (subjectIdx == -1) {
      subjectIdx = headers.indexWhere(
          (h) => h.toLowerCase() == mapping.subjectCol.toLowerCase());
    }
    if (dateIdx == -1) {
      dateIdx = headers.indexWhere(
          (h) => h.toLowerCase() == mapping.dateCol.toLowerCase());
    }
    if (statusIdx == -1) {
      statusIdx = headers.indexWhere(
          (h) => h.toLowerCase() == mapping.statusCol.toLowerCase());
    }

    if (subjectIdx == -1 || dateIdx == -1 || statusIdx == -1) {
      return ImportResult(
        importedRecords: [],
        errors: [
          ImportRowError(
            rowIndex: 0,
            rawRowData: {'headers': headers},
            errorMessage:
                'Required mapped columns missing: Subject column index=$subjectIdx, Date column index=$dateIdx, Status column index=$statusIdx',
          )
        ],
        totalRowsProcessed: 0,
        successfulRows: 0,
        newlyCreatedSubjects: [],
      );
    }

    int nextSubjectIdCounter = subjectNameToIdMap.values.fold(0, (max, id) => id > max ? id : max) + 1;

    for (int i = 0; i < rows.length; i++) {
      final rowIndex = i + 2; // 1-indexed header + 1
      final row = rows[i];

      final Map<String, dynamic> rawRowMap = {};
      for (int h = 0; h < headers.length; h++) {
        if (h < row.length) {
          rawRowMap[headers[h]] = row[h];
        }
      }

      if (row.length <= subjectIdx || row.length <= dateIdx || row.length <= statusIdx) {
        errors.add(ImportRowError(
          rowIndex: rowIndex,
          rawRowData: rawRowMap,
          errorMessage: 'Row contains insufficient columns',
        ));
        continue;
      }

      final rawSubject = row[subjectIdx]?.toString().trim() ?? '';
      final rawDate = row[dateIdx]?.toString().trim() ?? '';
      final rawStatus = row[statusIdx]?.toString().trim() ?? '';
      final rawIsLab = isLabIdx >= 0 && isLabIdx < row.length ? row[isLabIdx]?.toString().trim() : null;

      if (rawSubject.isEmpty) {
        errors.add(ImportRowError(
          rowIndex: rowIndex,
          rawRowData: rawRowMap,
          errorMessage: 'Subject name is empty',
        ));
        continue;
      }

      final DateTime? parsedDate = _parseDate(rawDate);
      if (parsedDate == null) {
        errors.add(ImportRowError(
          rowIndex: rowIndex,
          rawRowData: rawRowMap,
          errorMessage: 'Unparseable date value: "$rawDate"',
        ));
        continue;
      }

      final AttendanceStatus? parsedStatus = _parseStatus(rawStatus);
      if (parsedStatus == null) {
        errors.add(ImportRowError(
          rowIndex: rowIndex,
          rawRowData: rawRowMap,
          errorMessage: 'Unrecognized attendance status: "$rawStatus"',
        ));
        continue;
      }

      final bool isLab = _parseIsLab(rawIsLab, rawSubject);

      // Resolve subject ID
      int? subjectId = subjectNameToIdMap[rawSubject];
      if (subjectId == null) {
        subjectId = nextSubjectIdCounter++;
        subjectNameToIdMap[rawSubject] = subjectId;
        newSubjects.add(rawSubject);
      }

      records.add(AttendanceRecord(
        subjectId: subjectId,
        date: parsedDate,
        status: parsedStatus,
        isLab: isLab,
      ));
    }

    return ImportResult(
      importedRecords: records,
      errors: errors,
      totalRowsProcessed: rows.length,
      successfulRows: records.length,
      newlyCreatedSubjects: newSubjects,
    );
  }

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;

    // ISO-8601
    final tryIso = DateTime.tryParse(raw);
    if (tryIso != null) return tryIso;

    // Split YYYY-MM-DD or DD/MM/YYYY or MM/DD/YYYY
    final parts = raw.split(RegExp(r'[-/\.]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);

      if (p0 != null && p1 != null && p2 != null) {
        if (p0 > 1000) {
          // YYYY-MM-DD
          return DateTime(p0, p1, p2);
        } else if (p2 > 1000) {
          // DD/MM/YYYY or MM/DD/YYYY (assuming DD/MM/YYYY if p0 > 12)
          if (p0 > 12) {
            return DateTime(p2, p1, p0);
          } else {
            return DateTime(p2, p0, p1);
          }
        }
      }
    }
    return null;
  }

  static AttendanceStatus? _parseStatus(String raw) {
    final val = raw.trim().toLowerCase();
    if (val == 'p' || val == 'present' || val == '1' || val == 'true' || val == 'yes') {
      return AttendanceStatus.present;
    }
    if (val == 'a' || val == 'absent' || val == '0' || val == 'false' || val == 'no') {
      return AttendanceStatus.absent;
    }
    if (val == 'c' || val == 'cancelled' || val == 'canceled') {
      return AttendanceStatus.cancelled;
    }
    if (val.contains('medical') || val == 'ml' || val == 'm') {
      return AttendanceStatus.medicalLeave;
    }
    if (val.contains('duty') || val == 'dl' || val == 'od') {
      return AttendanceStatus.dutyLeave;
    }
    return null;
  }

  static bool _parseIsLab(String? rawIsLab, String rawSubject) {
    if (rawIsLab != null && rawIsLab.isNotEmpty) {
      final val = rawIsLab.trim().toLowerCase();
      if (val == 'lab' || val == '1' || val == 'true' || val == 'yes') {
        return true;
      }
    }
    if (rawSubject.toLowerCase().contains('lab') ||
        rawSubject.toLowerCase().contains('practical')) {
      return true;
    }
    return false;
  }
}
