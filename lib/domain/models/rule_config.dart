import 'dart:convert';

class RuleConfig {
  final String collegeId;
  final double thresholdPct;
  final String calculationMode; // "aggregate" or "per_subject"
  final List<String> excludedStatuses;
  final double labWeightMultiplier;
  final Map<String, double> perSubjectWeighting;

  const RuleConfig({
    required this.collegeId,
    required this.thresholdPct,
    required this.calculationMode,
    required this.excludedStatuses,
    required this.labWeightMultiplier,
    required this.perSubjectWeighting,
  });

  factory RuleConfig.fromJson(Map<String, dynamic> json) {
    final rawExcluded = json['excluded_statuses'] as List<dynamic>? ?? [];
    final excluded = rawExcluded.map((e) => e.toString().toLowerCase()).toList();

    final rawWeighting = json['per_subject_weighting'];
    Map<String, double> weighting = {};

    if (rawWeighting is Map<String, dynamic>) {
      rawWeighting.forEach((key, value) {
        if (value is num) {
          weighting[key] = value.toDouble();
        }
      });
    } else if (rawWeighting is String && rawWeighting.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawWeighting) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (value is num) {
            weighting[key] = value.toDouble();
          }
        });
      } catch (_) {}
    }

    return RuleConfig(
      collegeId: json['college_id'] as String? ?? 'default',
      thresholdPct: (json['threshold_pct'] as num? ?? 75.0).toDouble(),
      calculationMode: json['calculation_mode'] as String? ?? 'per_subject',
      excludedStatuses: excluded,
      labWeightMultiplier: (json['lab_weight_multiplier'] as num? ?? 1.0).toDouble(),
      perSubjectWeighting: weighting,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'college_id': collegeId,
      'threshold_pct': thresholdPct,
      'calculation_mode': calculationMode,
      'excluded_statuses': excludedStatuses,
      'lab_weight_multiplier': labWeightMultiplier,
      'per_subject_weighting': perSubjectWeighting,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'college_id': collegeId,
      'threshold_pct': thresholdPct,
      'calculation_mode': calculationMode,
      'excluded_statuses': jsonEncode(excludedStatuses),
      'lab_weight_multiplier': labWeightMultiplier,
      'per_subject_weighting': jsonEncode(perSubjectWeighting),
    };
  }

  factory RuleConfig.fromDbMap(Map<String, dynamic> map) {
    List<String> excluded = [];
    if (map['excluded_statuses'] is String) {
      try {
        final List<dynamic> parsed = jsonDecode(map['excluded_statuses']);
        excluded = parsed.map((e) => e.toString().toLowerCase()).toList();
      } catch (_) {}
    }

    Map<String, double> weighting = {};
    if (map['per_subject_weighting'] is String) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(map['per_subject_weighting']);
        parsed.forEach((key, value) {
          if (value is num) weighting[key] = value.toDouble();
        });
      } catch (_) {}
    }

    return RuleConfig(
      collegeId: map['college_id'] as String,
      thresholdPct: (map['threshold_pct'] as num).toDouble(),
      calculationMode: map['calculation_mode'] as String? ?? 'per_subject',
      excludedStatuses: excluded,
      labWeightMultiplier: (map['lab_weight_multiplier'] as num? ?? 1.0).toDouble(),
      perSubjectWeighting: weighting,
    );
  }
}
