import 'package:csv/csv.dart';
import '../models/import_result.dart';
import '../models/timetable_entry.dart';

class TimetableImportResult {
  final List<TimetableEntry> entries;
  final List<ImportRowError> errors;
  final int totalRowsProcessed;
  final int successfulRows;

  const TimetableImportResult({
    required this.entries,
    required this.errors,
    required this.totalRowsProcessed,
    required this.successfulRows,
  });

  bool get hasErrors => errors.isNotEmpty;
}

class TimetableImportEngine {
  /// Parse raw CSV string into timetable entries
  static TimetableImportResult processCsv({
    required String csvText,
    required Map<String, int> subjectNameToIdMap,
  }) {
    final constConverter = const CsvToListConverter(shouldParseNumbers: false);
    final List<List<dynamic>> rows = constConverter.convert(csvText);

    if (rows.isEmpty) {
      return const TimetableImportResult(
        entries: [],
        errors: [],
        totalRowsProcessed: 0,
        successfulRows: 0,
      );
    }

    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.sublist(1);

    // Auto-guess columns
    int subjectIdx = _findHeader(headers, ['subject', 'course', 'class']);
    int dayIdx = _findHeader(headers, ['day', 'day_of_week', 'weekday']);
    int startIdx = _findHeader(headers, ['start', 'start_time', 'time_start']);
    int endIdx = _findHeader(headers, ['end', 'end_time', 'time_end']);
    int roomIdx = _findHeader(headers, ['room', 'hall', 'venue', 'location']);

    // Fallbacks
    if (subjectIdx == -1 && headers.isNotEmpty) subjectIdx = 0;
    if (dayIdx == -1 && headers.length > 1) dayIdx = 1;
    if (startIdx == -1 && headers.length > 2) startIdx = 2;
    if (endIdx == -1 && headers.length > 3) endIdx = 3;
    if (roomIdx == -1 && headers.length > 4) roomIdx = 4;

    final List<TimetableEntry> entries = [];
    final List<ImportRowError> errors = [];
    int nextSubjectId = subjectNameToIdMap.values.fold(0, (max, id) => id > max ? id : max) + 1;

    for (int i = 0; i < dataRows.length; i++) {
      final rowIndex = i + 2;
      final row = dataRows[i];

      final Map<String, dynamic> rawRowMap = {};
      for (int h = 0; h < headers.length; h++) {
        if (h < row.length) rawRowMap[headers[h]] = row[h];
      }

      if (row.length <= subjectIdx || row.length <= dayIdx) {
        errors.add(ImportRowError(
          rowIndex: rowIndex,
          rawRowData: rawRowMap,
          errorMessage: 'Insufficient columns in timetable row',
        ));
        continue;
      }

      final rawSubject = row[subjectIdx]?.toString().trim() ?? '';
      final rawDay = row[dayIdx]?.toString().trim() ?? '';
      final rawStart = startIdx < row.length ? row[startIdx]?.toString().trim() ?? '' : '09:00 AM';
      final rawEnd = endIdx < row.length ? row[endIdx]?.toString().trim() ?? '' : '10:30 AM';
      final rawRoom = roomIdx < row.length ? row[roomIdx]?.toString().trim() ?? '' : 'Room 101';

      if (rawSubject.isEmpty) {
        errors.add(ImportRowError(
          rowIndex: rowIndex,
          rawRowData: rawRowMap,
          errorMessage: 'Subject name is empty',
        ));
        continue;
      }

      int? subjectId = subjectNameToIdMap[rawSubject];
      if (subjectId == null) {
        subjectId = nextSubjectId++;
        subjectNameToIdMap[rawSubject] = subjectId;
      }

      final bool isLab = rawSubject.toLowerCase().contains('lab') || rawSubject.toLowerCase().contains('practical');

      entries.add(TimetableEntry(
        subjectId: subjectId,
        subjectName: rawSubject,
        dayOfWeek: _normalizeDay(rawDay),
        startTime: rawStart,
        endTime: rawEnd,
        room: rawRoom,
        isLab: isLab,
      ));
    }

    return TimetableImportResult(
      entries: entries,
      errors: errors,
      totalRowsProcessed: dataRows.length,
      successfulRows: entries.length,
    );
  }

  static int _findHeader(List<String> headers, List<String> keywords) {
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase();
      if (keywords.any((k) => h.contains(k))) return i;
    }
    return -1;
  }

  static String _normalizeDay(String raw) {
    final d = raw.trim().toLowerCase();
    if (d.startsWith('mon')) return 'Monday';
    if (d.startsWith('tue')) return 'Tuesday';
    if (d.startsWith('wed')) return 'Wednesday';
    if (d.startsWith('thu')) return 'Thursday';
    if (d.startsWith('fri')) return 'Friday';
    if (d.startsWith('sat')) return 'Saturday';
    if (d.startsWith('sun')) return 'Sunday';
    return 'Monday';
  }
}
