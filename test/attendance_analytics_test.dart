import 'package:flutter_test/flutter_test.dart';
import 'package:saas/domain/usecases/attendance_analytics_engine.dart';

void main() {
  group('Attendance Analytics Unit Tests (Safe-Bunk & Recovery Calculator)', () {
    test('Edge Case 1: Subject with zero classes held yet', () {
      final res = SubjectAnalyticsResult.compute(
        subjectId: 1,
        subjectName: 'Compiler Design',
        attendedWeight: 0.0,
        eligibleWeight: 0.0,
        totalClassesHeld: 0,
        attendedClasses: 0,
        thresholdPct: 75.0,
      );

      expect(res.currentPercentage, equals(100.0));
      expect(res.hasClassesHeld, isFalse);
      expect(res.isBelowThreshold, isFalse);
      expect(res.isAtExactThreshold, isFalse);
      expect(res.safeBunkCount, equals(0));
      expect(res.recoveryCount, equals(0));
    });

    test('Edge Case 2: Subject at exactly threshold (e.g. 75% attended out of 75% threshold)', () {
      // 3 attended out of 4 classes = 75.0%
      final res = SubjectAnalyticsResult.compute(
        subjectId: 2,
        subjectName: 'Data Structures',
        attendedWeight: 3.0,
        eligibleWeight: 4.0,
        totalClassesHeld: 4,
        attendedClasses: 3,
        thresholdPct: 75.0,
      );

      expect(res.currentPercentage, equals(75.0));
      expect(res.isAtExactThreshold, isTrue);
      expect(res.isBelowThreshold, isFalse);
      // If student bunks 1 more class: (3 / 5) = 60% < 75%. Safe bunks MUST be 0!
      expect(res.safeBunkCount, equals(0));
      expect(res.recoveryCount, equals(0));
    });

    test('Edge Case 3: Subject above threshold (Safe-Bunk Calculation)', () {
      // 8 attended out of 10 classes = 80.0% vs 75% threshold
      // Formula: B <= (8.0 / 0.75 - 10) = 10.666 - 10 = 0.666 -> floor = 0 bunks
      final res1 = SubjectAnalyticsResult.compute(
        subjectId: 3,
        subjectName: 'Mathematics',
        attendedWeight: 8.0,
        eligibleWeight: 10.0,
        totalClassesHeld: 10,
        attendedClasses: 8,
        thresholdPct: 75.0,
      );
      expect(res1.currentPercentage, equals(80.0));
      expect(res1.safeBunkCount, equals(0)); // 8/11 = 72.7% < 75%, so 0 safe bunks

      // 90 attended out of 100 classes = 90.0% vs 75% threshold
      // Formula: B <= (90 / 0.75 - 100) = 120 - 100 = 20 safe bunks
      final res2 = SubjectAnalyticsResult.compute(
        subjectId: 4,
        subjectName: 'Physics',
        attendedWeight: 90.0,
        eligibleWeight: 100.0,
        totalClassesHeld: 100,
        attendedClasses: 90,
        thresholdPct: 75.0,
      );
      expect(res2.currentPercentage, equals(90.0));
      expect(res2.safeBunkCount, equals(20));

      // Verification: If user bunks 20 classes -> 90 / 120 = 75.0% (exactly at threshold!)
      // If user bunks 21 classes -> 90 / 121 = 74.38% (drops below threshold!)
    });

    test('Edge Case 4: Subject below threshold (Recovery Calculator)', () {
      // 5 attended out of 10 classes = 50.0% vs 75% threshold
      // Formula: R >= (0.75 * 10 - 5) / (1 - 0.75) = (7.5 - 5) / 0.25 = 2.5 / 0.25 = 10 lectures!
      final res = SubjectAnalyticsResult.compute(
        subjectId: 5,
        subjectName: 'Operating Systems',
        attendedWeight: 5.0,
        eligibleWeight: 10.0,
        totalClassesHeld: 10,
        attendedClasses: 5,
        thresholdPct: 75.0,
      );

      expect(res.currentPercentage, equals(50.0));
      expect(res.isBelowThreshold, isTrue);
      expect(res.safeBunkCount, equals(0));
      expect(res.recoveryCount, equals(10));

      // Verification:
      // If user attends 9 consecutive classes -> (5+9)/(10+9) = 14/19 = 73.68% < 75%
      // If user attends 10 consecutive classes -> (5+10)/(10+10) = 15/20 = 75.0% >= 75%
    });

    test('Edge Case 5: 100% threshold with missed class (Unrecoverable)', () {
      final res = SubjectAnalyticsResult.compute(
        subjectId: 6,
        subjectName: 'Ethics',
        attendedWeight: 9.0,
        eligibleWeight: 10.0,
        totalClassesHeld: 10,
        attendedClasses: 9,
        thresholdPct: 100.0,
      );

      expect(res.currentPercentage, equals(90.0));
      expect(res.isBelowThreshold, isTrue);
      expect(res.isRecoverable, isFalse);
    });
  });
}
