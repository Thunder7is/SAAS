class ColumnMapping {
  final String collegeId;
  final String subjectCol;
  final String dateCol;
  final String statusCol;
  final String? isLabCol;
  final DateTime updatedAt;

  const ColumnMapping({
    required this.collegeId,
    required this.subjectCol,
    required this.dateCol,
    required this.statusCol,
    this.isLabCol,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'college_id': collegeId,
      'subject_col': subjectCol,
      'date_col': dateCol,
      'status_col': statusCol,
      'is_lab_col': isLabCol,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ColumnMapping.fromMap(Map<String, dynamic> map) {
    return ColumnMapping(
      collegeId: map['college_id'] as String,
      subjectCol: map['subject_col'] as String,
      dateCol: map['date_col'] as String,
      statusCol: map['status_col'] as String,
      isLabCol: map['is_lab_col'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Automatically guess column mappings based on header text heuristics
  static ColumnMapping autoGuess({
    required String collegeId,
    required List<String> headers,
  }) {
    String? subjectMatch;
    String? dateMatch;
    String? statusMatch;
    String? isLabMatch;

    for (var header in headers) {
      final h = header.trim().toLowerCase();

      // Subject heuristics
      if (subjectMatch == null) {
        if (h.contains('subject') ||
            h.contains('course') ||
            h.contains('class_name') ||
            h == 'title' ||
            h == 'code') {
          subjectMatch = header;
        }
      }

      // Date heuristics
      if (dateMatch == null) {
        if (h.contains('date') ||
            h.contains('time') ||
            h.contains('timestamp') ||
            h == 'day') {
          dateMatch = header;
        }
      }

      // Status heuristics
      if (statusMatch == null) {
        if (h.contains('status') ||
            h.contains('attendance') ||
            h.contains('presence') ||
            h == 'state' ||
            h == 'present') {
          statusMatch = header;
        }
      }

      // Is Lab heuristics
      if (isLabMatch == null) {
        if (h.contains('lab') ||
            h.contains('is_lab') ||
            h.contains('session_type') ||
            h == 'type') {
          isLabMatch = header;
        }
      }
    }

    // Fallbacks if heuristics didn't find exact matches
    subjectMatch ??= headers.isNotEmpty ? headers[0] : 'subject';
    dateMatch ??= headers.length > 1 ? headers[1] : 'date';
    statusMatch ??= headers.length > 2 ? headers[2] : 'status';

    return ColumnMapping(
      collegeId: collegeId,
      subjectCol: subjectMatch,
      dateCol: dateMatch,
      statusCol: statusMatch,
      isLabCol: isLabMatch,
      updatedAt: DateTime.now(),
    );
  }
}
