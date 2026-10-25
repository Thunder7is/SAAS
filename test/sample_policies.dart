import 'package:saas/domain/models/rule_config.dart';

class SamplePolicies {
  /// Policy 1: Strict Standard Policy
  /// - 75% threshold
  /// - per_subject mode (all subjects must pass)
  /// - Only 'cancelled' is excluded (Medical leave counts as absent!)
  /// - 1.0 lab multiplier
  static final Map<String, dynamic> policy1StrictJson = {
    'college_id': 'college_strict_75',
    'threshold_pct': 75.0,
    'calculation_mode': 'per_subject',
    'excluded_statuses': ['cancelled'],
    'lab_weight_multiplier': 1.0,
    'per_subject_weighting': <String, double>{},
  };

  /// Policy 2: Flexible Medical & Weighted Labs Policy
  /// - 75% threshold
  /// - aggregate mode (total aggregate percentage across all subjects)
  /// - Excludes 'cancelled' AND 'medical_leave'
  /// - 2.0 lab multiplier (labs count twice as much)
  static final Map<String, dynamic> policy2FlexibleJson = {
    'college_id': 'college_flexible_medical',
    'threshold_pct': 75.0,
    'calculation_mode': 'aggregate',
    'excluded_statuses': ['cancelled', 'medical_leave'],
    'lab_weight_multiplier': 2.0,
    'per_subject_weighting': <String, double>{},
  };

  /// Policy 3: Core Subject Weighted & High Threshold Policy
  /// - 80% threshold
  /// - per_subject mode
  /// - Excludes 'cancelled' and 'duty_leave'
  /// - 1.5 lab multiplier
  /// - Data Structures has 2.0x subject weight factor
  static final Map<String, dynamic> policy3WeightedJson = {
    'college_id': 'college_core_weighted',
    'threshold_pct': 80.0,
    'calculation_mode': 'per_subject',
    'excluded_statuses': ['cancelled', 'duty_leave'],
    'lab_weight_multiplier': 1.5,
    'per_subject_weighting': <String, double>{
      'Data Structures': 2.0,
      'Algorithms': 1.5,
    },
  };

  static RuleConfig get policy1 => RuleConfig.fromJson(policy1StrictJson);
  static RuleConfig get policy2 => RuleConfig.fromJson(policy2FlexibleJson);
  static RuleConfig get policy3 => RuleConfig.fromJson(policy3WeightedJson);
}
