class TimetableEntry {
  final int? id;
  final int subjectId;
  final String subjectName;
  final String dayOfWeek; // e.g. "Monday", "Tuesday", etc.
  final String startTime; // e.g. "09:00 AM"
  final String endTime;   // e.g. "10:30 AM"
  final String room;      // e.g. "Lab 3"
  final bool isLab;

  const TimetableEntry({
    this.id,
    required this.subjectId,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.isLab = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'is_lab': isLab ? 1 : 0,
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      subjectName: map['subject_name'] as String,
      dayOfWeek: map['day_of_week'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      room: map['room'] as String,
      isLab: (map['is_lab'] as int? ?? 0) == 1,
    );
  }

  TimetableEntry copyWith({
    int? id,
    int? subjectId,
    String? subjectName,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
    bool? isLab,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      isLab: isLab ?? this.isLab,
    );
  }
}
