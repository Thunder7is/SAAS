import '../models/attendance_record.dart';
import '../models/rule_config.dart';
import '../models/subject.dart';
import 'attendance_analytics_engine.dart';

class SubjectAttendanceDetail {
  final int subjectId;
  final String subjectName;
  final double percentage;
  final double attendedWeight;
  final double eligibleWeight;
  final int totalClasses;
  final int attendedClasses;
  final bool satisfiesThreshold;
  final SubjectAnalyticsResult analytics;

  const SubjectAttendanceDetail({
    required this.subjectId,
    required this.subjectName,
    required this.percentage,
    required this.attendedWeight,
    required this.eligibleWeight,
    required this.totalClasses,
    required this.attendedClasses,
    required this.satisfiesThreshold,
    required this.analytics,
  });
}

class AttendanceCalculationResult {
  final double aggregatePercentage;
  final Map<int, SubjectAttendanceDetail> subjectDetails;
  final bool isOverallCompliant;
  final String calculationMode;
  final double thresholdPct;

  const AttendanceCalculationResult({
    required this.aggregatePercentage,
    required this.subjectDetails,
    required this.isOverallCompliant,
    required this.calculationMode,
    required this.thresholdPct,
  });
}

/// Pure functional attendance rule engine class with zero side-effects.
class AttendanceRuleEngine {
  /// Pure function that calculates attendance analytics for a set of records, subjects, and rule configuration.
  static AttendanceCalculationResult calculate({
    required List<AttendanceRecord> records,
    required List<Subject> subjects,
    required RuleConfig config,
  }) {
    final Map<int, Subject> subjectMap = {
      for (var s in subjects) if (s.id != null) s.id!: s
    };

    final Map<int, double> attendedWeights = {};
    final Map<int, double> eligibleWeights = {};
    final Map<int, int> totalClassCounts = {};
    final Map<int, int> attendedClassCounts = {};

    for (var subject in subjects) {
      if (subject.id != null) {
        attendedWeights[subject.id!] = 0.0;
        eligibleWeights[subject.id!] = 0.0;
        totalClassCounts[subject.id!] = 0;
        attendedClassCounts[subject.id!] = 0;
      }
    }

    final normalizedExcluded = config.excludedStatuses
        .map((s) => s.trim().toLowerCase())
        .toSet();

    for (var record in records) {
      final statusStr = record.status.toValue().toLowerCase();

      // Exclude statuses specified in college rule config (e.g. medical_leave, cancelled)
      if (normalizedExcluded.contains(statusStr)) {
        continue;
      }

      final subject = subjectMap[record.subjectId];
      final subjectName = subject?.name ?? '';

      // Determine subject custom weight multiplier
      double subjectMultiplier = 1.0;
      if (config.perSubjectWeighting.containsKey(subjectName)) {
        subjectMultiplier = config.perSubjectWeighting[subjectName]!;
      } else if (config.perSubjectWeighting.containsKey(record.subjectId.toString())) {
        subjectMultiplier = config.perSubjectWeighting[record.subjectId.toString()]!;
      }

      // Lab weight multiplier applies if session is a lab
      final double labMultiplier = record.isLab ? config.labWeightMultiplier : 1.0;

      final double sessionWeight = 1.0 * labMultiplier * subjectMultiplier;

      eligibleWeights[record.subjectId] =
          (eligibleWeights[record.subjectId] ?? 0.0) + sessionWeight;
      totalClassCounts[record.subjectId] =
          (totalClassCounts[record.subjectId] ?? 0) + 1;

      if (record.status == AttendanceStatus.present) {
        attendedWeights[record.subjectId] =
            (attendedWeights[record.subjectId] ?? 0.0) + sessionWeight;
        attendedClassCounts[record.subjectId] =
            (attendedClassCounts[record.subjectId] ?? 0) + 1;
      }
    }

    final Map<int, SubjectAttendanceDetail> subjectDetails = {};
    double totalGlobalAttendedWeight = 0.0;
    double totalGlobalEligibleWeight = 0.0;

    for (var subject in subjects) {
      final subId = subject.id;
      if (subId == null) continue;

      final attendedW = attendedWeights[subId] ?? 0.0;
      final eligibleW = eligibleWeights[subId] ?? 0.0;
      final totalC = totalClassCounts[subId] ?? 0;
      final attendedC = attendedClassCounts[subId] ?? 0;

      final analytics = SubjectAnalyticsResult.compute(
        subjectId: subId,
        subjectName: subject.name,
        attendedWeight: attendedW,
        eligibleWeight: eligibleW,
        totalClassesHeld: totalC,
        attendedClasses: attendedC,
        thresholdPct: config.thresholdPct,
      );

      subjectDetails[subId] = SubjectAttendanceDetail(
        subjectId: subId,
        subjectName: subject.name,
        percentage: analytics.currentPercentage,
        attendedWeight: attendedW,
        eligibleWeight: eligibleW,
        totalClasses: totalC,
        attendedClasses: attendedC,
        satisfiesThreshold: !analytics.isBelowThreshold,
        analytics: analytics,
      );

      totalGlobalAttendedWeight += attendedW;
      totalGlobalEligibleWeight += eligibleW;
    }

    double aggregatePct = 100.0;
    if (totalGlobalEligibleWeight > 0) {
      aggregatePct = (totalGlobalAttendedWeight / totalGlobalEligibleWeight) * 100.0;
    }
    aggregatePct = double.parse(aggregatePct.toStringAsFixed(2));

    bool isOverallCompliant;
    if (config.calculationMode.toLowerCase() == 'per_subject') {
      isOverallCompliant = subjectDetails.values.every((d) => d.satisfiesThreshold);
    } else {
      isOverallCompliant = aggregatePct >= config.thresholdPct;
    }

    return AttendanceCalculationResult(
      aggregatePercentage: aggregatePct,
      subjectDetails: subjectDetails,
      isOverallCompliant: isOverallCompliant,
      calculationMode: config.calculationMode,
      thresholdPct: config.thresholdPct,
    );
  }
}
