import '../models/attendance_record.dart';

class ImportConflict {
  final AttendanceRecord existingManualRecord;
  final AttendanceRecord incomingImportedRecord;
  final String subjectName;

  const ImportConflict({
    required this.existingManualRecord,
    required this.incomingImportedRecord,
    required this.subjectName,
  });

  @override
  String toString() =>
      'Conflict on $subjectName (${existingManualRecord.date.toIso8601String().split('T')[0]}): '
      'Manual=${existingManualRecord.status.toValue()} vs Imported=${incomingImportedRecord.status.toValue()}';
}

class ReconciliationResult {
  final List<AttendanceRecord> recordsToSave;
  final List<ImportConflict> conflicts;
  final int autoMergedCount;
  final int newInsertedCount;

  const ReconciliationResult({
    required this.recordsToSave,
    required this.conflicts,
    required this.autoMergedCount,
    required this.newInsertedCount,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
}

/// Pure functional engine that reconciles manual entries against incoming imported records.
class ReconciliationEngine {
  /// Compares incoming imported records with existing records in local SQLite storage.
  /// Detects conflicts between manual vs imported records on the same subject & date.
  static ReconciliationResult reconcile({
    required List<AttendanceRecord> existingRecords,
    required List<AttendanceRecord> incomingRecords,
    required Map<int, String> subjectIdToNameMap,
  }) {
    final Map<String, AttendanceRecord> existingMap = {};
    for (var rec in existingRecords) {
      final key = _makeKey(rec.subjectId, rec.date);
      existingMap[key] = rec;
    }

    final List<AttendanceRecord> toSave = [];
    final List<ImportConflict> conflicts = [];
    int autoMerged = 0;
    int newInserted = 0;

    for (var incoming in incomingRecords) {
      final key = _makeKey(incoming.subjectId, incoming.date);
      final existing = existingMap[key];

      if (existing == null) {
        // New record -> Save as imported
        toSave.add(incoming.copyWith(source: RecordSource.imported));
        newInserted++;
      } else {
        // Record exists for same subject & date
        if (existing.source == RecordSource.manual) {
          if (existing.status == incoming.status) {
            // Statuses match! Auto-reconcile to imported source
            toSave.add(existing.copyWith(source: RecordSource.imported));
            autoMerged++;
          } else {
            // CONFLICT: Manual status disagrees with official imported sheet!
            conflicts.add(ImportConflict(
              existingManualRecord: existing,
              incomingImportedRecord: incoming,
              subjectName: subjectIdToNameMap[incoming.subjectId] ?? 'Subject #${incoming.subjectId}',
            ));
          }
        } else {
          // Existing record is already imported -> Overwrite with latest import data
          toSave.add(incoming.copyWith(id: existing.id, source: RecordSource.imported));
        }
      }
    }

    return ReconciliationResult(
      recordsToSave: toSave,
      conflicts: conflicts,
      autoMergedCount: autoMerged,
      newInsertedCount: newInserted,
    );
  }

  static String _makeKey(int subjectId, DateTime date) {
    return '${subjectId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
