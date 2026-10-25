import 'package:flutter_test/flutter_test.dart';
import 'package:saas/domain/models/attendance_record.dart';
import 'package:saas/domain/models/subject.dart';
import 'package:saas/domain/usecases/attendance_rule_engine.dart';

import 'sample_policies.dart';

void main() {
  group('AttendanceRuleEngine Unit Tests', () {
    final List<Subject> testSubjects = [
      const Subject(id: 1, name: 'Data Structures', collegeId: 'test_col'),
      const Subject(id: 2, name: 'Database Systems', collegeId: 'test_col'),
      const Subject(id: 3, name: 'Mathematics', collegeId: 'test_col'),
    ];

    // Raw dataset with diverse session types, medical leave, duty leave, cancelled classes, and labs
    final List<AttendanceRecord> rawAttendanceData = [
      // Data Structures (id: 1)
      AttendanceRecord(
          id: 101, subjectId: 1, date: DateTime(2026, 8, 1), status: AttendanceStatus.present, isLab: false),
      AttendanceRecord(
          id: 102, subjectId: 1, date: DateTime(2026, 8, 2), status: AttendanceStatus.present, isLab: true),
      AttendanceRecord(
          id: 103, subjectId: 1, date: DateTime(2026, 8, 3), status: AttendanceStatus.medicalLeave, isLab: false),
      AttendanceRecord(
          id: 104, subjectId: 1, date: DateTime(2026, 8, 4), status: AttendanceStatus.absent, isLab: true),

      // Database Systems (id: 2)
      AttendanceRecord(
          id: 201, subjectId: 2, date: DateTime(2026, 8, 1), status: AttendanceStatus.present, isLab: false),
      AttendanceRecord(
          id: 202, subjectId: 2, date: DateTime(2026, 8, 2), status: AttendanceStatus.present, isLab: false),
      AttendanceRecord(
          id: 203, subjectId: 2, date: DateTime(2026, 8, 3), status: AttendanceStatus.dutyLeave, isLab: false),
      AttendanceRecord(
          id: 204, subjectId: 2, date: DateTime(2026, 8, 4), status: AttendanceStatus.cancelled, isLab: false),

      // Mathematics (id: 3)
      AttendanceRecord(
          id: 301, subjectId: 3, date: DateTime(2026, 8, 1), status: AttendanceStatus.absent, isLab: false),
      AttendanceRecord(
          id: 302, subjectId: 3, date: DateTime(2026, 8, 2), status: AttendanceStatus.present, isLab: false),
      AttendanceRecord(
          id: 303, subjectId: 3, date: DateTime(2026, 8, 3), status: AttendanceStatus.present, isLab: false),
    ];

    test('Policy 1 (Strict Standard) calculates strict per-subject percentages', () {
      final res1 = AttendanceRuleEngine.calculate(
        records: rawAttendanceData,
        subjects: testSubjects,
        config: SamplePolicies.policy1,
      );

      expect(res1.calculationMode, equals('per_subject'));
      expect(res1.thresholdPct, equals(75.0));

      // Subject 1 (Data Structures): Medical leave is NOT excluded under Policy 1 -> counted as eligible.
      // Classes: Present(Theory 1), Present(Lab 1), MedicalLeave(Theory 1), Absent(Lab 1). Total 4. Attended 2. Pct: 50.0%
      expect(res1.subjectDetails[1]!.percentage, equals(50.0));
      expect(res1.subjectDetails[1]!.satisfiesThreshold, isFalse);

      // Overall compliance under per_subject mode should be false because Subject 1 fails 75%
      expect(res1.isOverallCompliant, isFalse);
    });

    test('Policy 2 (Flexible Medical & Weighted Labs) excludes medical leave and weights labs 2x', () {
      final res2 = AttendanceRuleEngine.calculate(
        records: rawAttendanceData,
        subjects: testSubjects,
        config: SamplePolicies.policy2,
      );

      expect(res2.calculationMode, equals('aggregate'));
      expect(res2.thresholdPct, equals(75.0));

      // Under Policy 2, Medical Leave IS excluded.
      // Subject 1 (Data Structures):
      // Theory Present (w:1.0), Lab Present (w:2.0), Medical Leave (EXCLUDED), Lab Absent (w:2.0).
      // Attended Weight: 1.0 + 2.0 = 3.0. Eligible Weight: 1.0 + 2.0 + 2.0 = 5.0.
      // Pct: 3.0 / 5.0 = 60.0%
      expect(res2.subjectDetails[1]!.percentage, equals(60.0));

      // Aggregate percentage is calculated across all weighted sessions
      expect(res2.aggregatePercentage, isNot(equals(50.0)));
    });

    test('Policy 3 (Core Weighted & 80% Threshold) applies custom subject multiplier & duty leave exclusion', () {
      final res3 = AttendanceRuleEngine.calculate(
        records: rawAttendanceData,
        subjects: testSubjects,
        config: SamplePolicies.policy3,
      );

      expect(res3.calculationMode, equals('per_subject'));
      expect(res3.thresholdPct, equals(80.0));

      // Subject 2 (Database Systems): Duty Leave is EXCLUDED in Policy 3.
      // Session 203 (dutyLeave) is skipped.
      // Attended: 2, Total: 2. Pct: 100.0%
      expect(res3.subjectDetails[2]!.percentage, equals(100.0));
      expect(res3.subjectDetails[2]!.satisfiesThreshold, isTrue);
    });

    test('Proves all 3 policies produce DISTINCT computed results on identical raw dataset', () {
      final res1 = AttendanceRuleEngine.calculate(
        records: rawAttendanceData,
        subjects: testSubjects,
        config: SamplePolicies.policy1,
      );

      final res2 = AttendanceRuleEngine.calculate(
        records: rawAttendanceData,
        subjects: testSubjects,
        config: SamplePolicies.policy2,
      );

      final res3 = AttendanceRuleEngine.calculate(
        records: rawAttendanceData,
        subjects: testSubjects,
        config: SamplePolicies.policy3,
      );

      // Verify aggregate percentages are different
      expect(res1.aggregatePercentage, isNot(equals(res2.aggregatePercentage)));
      expect(res2.aggregatePercentage, isNot(equals(res3.aggregatePercentage)));

      // Verify Data Structures percentages are different
      final dsPct1 = res1.subjectDetails[1]!.percentage;
      final dsPct2 = res2.subjectDetails[1]!.percentage;
      final dsPct3 = res3.subjectDetails[1]!.percentage;

      expect(dsPct1, equals(50.0));
      expect(dsPct2, equals(60.0));
      expect(dsPct3, equals(42.86)); // 3.0 attended weight / 7.0 eligible weight (with 2.0x sub weight and 1.5x lab)
      expect(dsPct1, isNot(equals(dsPct2)));
      expect(dsPct2, isNot(equals(dsPct3)));
    });
  });
}
