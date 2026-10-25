enum AttendanceStatus {
  present,
  absent,
  cancelled,
  medicalLeave,
  dutyLeave;

  String toValue() {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.cancelled:
        return 'cancelled';
      case AttendanceStatus.medicalLeave:
        return 'medical_leave';
      case AttendanceStatus.dutyLeave:
        return 'duty_leave';
    }
  }

  static AttendanceStatus fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'cancelled':
        return AttendanceStatus.cancelled;
      case 'medical_leave':
      case 'medicalleave':
        return AttendanceStatus.medicalLeave;
      case 'duty_leave':
      case 'dutyleave':
        return AttendanceStatus.dutyLeave;
      default:
        return AttendanceStatus.absent;
    }
  }
}

enum RecordSource {
  manual,
  imported;

  String toValue() => this == RecordSource.manual ? 'manual' : 'imported';

  static RecordSource fromValue(String? value) {
    if (value == null) return RecordSource.manual;
    return value.toLowerCase() == 'imported' ? RecordSource.imported : RecordSource.manual;
  }
}

class AttendanceRecord {
  final int? id;
  final int subjectId;
  final DateTime date;
  final AttendanceStatus status;
  final bool isLab;
  final RecordSource source;

  const AttendanceRecord({
    this.id,
    required this.subjectId,
    required this.date,
    required this.status,
    this.isLab = false,
    this.source = RecordSource.manual,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'date': date.toIso8601String(),
      'status': status.toValue(),
      'is_lab': isLab ? 1 : 0,
      'source': source.toValue(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      date: DateTime.parse(map['date'] as String),
      status: AttendanceStatus.fromValue(map['status'] as String),
      isLab: (map['is_lab'] as int? ?? 0) == 1,
      source: RecordSource.fromValue(map['source'] as String?),
    );
  }

  AttendanceRecord copyWith({
    int? id,
    int? subjectId,
    DateTime? date,
    AttendanceStatus? status,
    bool? isLab,
    RecordSource? source,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      status: status ?? this.status,
      isLab: isLab ?? this.isLab,
      source: source ?? this.source,
    );
  }
}
