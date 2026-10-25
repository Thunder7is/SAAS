import 'dart:math';

class SubjectAnalyticsResult {
  final int subjectId;
  final String subjectName;
  final double currentPercentage;
  final double attendedWeight;
  final double eligibleWeight;
  final int totalClassesHeld;
  final int attendedClasses;
  final bool hasClassesHeld;
  final bool isBelowThreshold;
  final bool isAtExactThreshold;
  final int safeBunkCount;
  final int recoveryCount;
  final bool isRecoverable;
  final double thresholdPct;

  const SubjectAnalyticsResult({
    required this.subjectId,
    required this.subjectName,
    required this.currentPercentage,
    required this.attendedWeight,
    required this.eligibleWeight,
    required this.totalClassesHeld,
    required this.attendedClasses,
    required this.hasClassesHeld,
    required this.isBelowThreshold,
    required this.isAtExactThreshold,
    required this.safeBunkCount,
    required this.recoveryCount,
    required this.isRecoverable,
    required this.thresholdPct,
  });

  /// Factory method calculating (a) percentage, (b) safe bunk count, (c) recovery lectures needed.
  factory SubjectAnalyticsResult.compute({
    required int subjectId,
    required String subjectName,
    required double attendedWeight,
    required double eligibleWeight,
    required int totalClassesHeld,
    required int attendedClasses,
    required double thresholdPct,
    double futureClassWeight = 1.0,
  }) {
    final bool hasClasses = totalClassesHeld > 0 && eligibleWeight > 0;

    // (a) Current Attendance Percentage
    double currentPct = 100.0;
    if (hasClasses) {
      currentPct = (attendedWeight / eligibleWeight) * 100.0;
    }
    currentPct = double.parse(currentPct.toStringAsFixed(2));

    final double targetRatio = thresholdPct / 100.0;
    final bool isBelow = hasClasses && currentPct < thresholdPct;
    final bool isExact = hasClasses && (currentPct - thresholdPct).abs() < 0.001;

    // Edge case 1: Zero classes held yet
    if (!hasClasses) {
      return SubjectAnalyticsResult(
        subjectId: subjectId,
        subjectName: subjectName,
        currentPercentage: 100.0,
        attendedWeight: 0.0,
        eligibleWeight: 0.0,
        totalClassesHeld: 0,
        attendedClasses: 0,
        hasClassesHeld: false,
        isBelowThreshold: false,
        isAtExactThreshold: false,
        safeBunkCount: 0,
        recoveryCount: 0,
        isRecoverable: true,
        thresholdPct: thresholdPct,
      );
    }

    // (b) Safe Bunk Calculator
    // How many future classes (weight = futureClassWeight) can be missed while staying >= threshold?
    // Formula: (Wa) / (We + B * w_miss) >= T => B <= (Wa / T - We) / w_miss
    int safeBunks = 0;
    if (currentPct >= thresholdPct && targetRatio > 0) {
      final maxEligibleWeight = attendedWeight / targetRatio;
      final maxExtraWeight = maxEligibleWeight - eligibleWeight;
      if (maxExtraWeight > 0) {
        safeBunks = (maxExtraWeight / futureClassWeight).floor();
        if (safeBunks < 0) safeBunks = 0;
      }
    }

    // (c) Minimum Lectures Needed to Recover
    // How many consecutive future classes (weight = futureClassWeight) must be attended to reach >= threshold?
    // Formula: (Wa + R * w_att) / (We + R * w_att) >= T
    // => Wa + R * w_att >= T * We + T * R * w_att
    // => R * w_att * (1 - T) >= T * We - Wa
    // => R >= (T * We - Wa) / (w_att * (1 - T))
    int recoveryLectures = 0;
    bool isRecoverable = true;

    if (currentPct < thresholdPct) {
      if (targetRatio >= 1.0) {
        // If threshold is 100% and user missed a class, recovery is impossible!
        isRecoverable = false;
        recoveryLectures = 9999;
      } else {
        final numerator = (targetRatio * eligibleWeight) - attendedWeight;
        final denominator = futureClassWeight * (1.0 - targetRatio);
        if (numerator > 0 && denominator > 0) {
          recoveryLectures = (numerator / denominator).ceil();
        }
      }
    }

    return SubjectAnalyticsResult(
      subjectId: subjectId,
      subjectName: subjectName,
      currentPercentage: currentPct,
      attendedWeight: attendedWeight,
      eligibleWeight: eligibleWeight,
      totalClassesHeld: totalClassesHeld,
      attendedClasses: attendedClasses,
      hasClassesHeld: true,
      isBelowThreshold: isBelow,
      isAtExactThreshold: isExact,
      safeBunkCount: safeBunks,
      recoveryCount: recoveryLectures,
      isRecoverable: isRecoverable,
      thresholdPct: thresholdPct,
    );
  }
}
