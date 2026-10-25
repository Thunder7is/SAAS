import '../models/rule_config.dart';

abstract class RuleConfigRepository {
  Future<RuleConfig?> getRuleConfigByCollege(String collegeId);
  Future<int> saveRuleConfig(RuleConfig config);
  Future<int> deleteRuleConfig(String collegeId);
}
