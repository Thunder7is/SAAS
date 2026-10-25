import '../../domain/models/rule_config.dart';
import '../../domain/repositories/rule_config_repository.dart';
import '../datasources/local/database_helper.dart';

class RuleConfigRepositoryImpl implements RuleConfigRepository {
  final DatabaseHelper dbHelper;

  RuleConfigRepositoryImpl({DatabaseHelper? helper})
      : dbHelper = helper ?? DatabaseHelper.instance;

  @override
  Future<RuleConfig?> getRuleConfigByCollege(String collegeId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'rule_configs',
      where: 'college_id = ?',
      whereArgs: [collegeId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return RuleConfig.fromDbMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> saveRuleConfig(RuleConfig config) async {
    final db = await dbHelper.database;
    return await db.insert(
      'rule_configs',
      config.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> deleteRuleConfig(String collegeId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'rule_configs',
      where: 'college_id = ?',
      whereArgs: [collegeId],
    );
  }
}
