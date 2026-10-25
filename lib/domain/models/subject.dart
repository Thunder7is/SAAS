class Subject {
  final int? id;
  final String name;
  final String collegeId;

  const Subject({
    this.id,
    required this.name,
    required this.collegeId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'college_id': collegeId,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      name: map['name'] as String,
      collegeId: map['college_id'] as String,
    );
  }

  Subject copyWith({
    int? id,
    String? name,
    String? collegeId,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      collegeId: collegeId ?? this.collegeId,
    );
  }
}
