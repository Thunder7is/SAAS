import 'package:sqflite/sqflite.dart';
import '../../domain/models/column_mapping.dart';
import '../../domain/repositories/column_mapping_repository.dart';
import '../datasources/local/database_helper.dart';

class ColumnMappingRepositoryImpl implements ColumnMappingRepository {
  final DatabaseHelper dbHelper;

  ColumnMappingRepositoryImpl({DatabaseHelper? helper})
      : dbHelper = helper ?? DatabaseHelper.instance;

  @override
  Future<ColumnMapping?> getColumnMapping(String collegeId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'column_mappings',
      where: 'college_id = ?',
      whereArgs: [collegeId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ColumnMapping.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> saveColumnMapping(ColumnMapping mapping) async {
    final db = await dbHelper.database;
    return await db.insert(
      'column_mappings',
      mapping.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> deleteColumnMapping(String collegeId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'column_mappings',
      where: 'college_id = ?',
      whereArgs: [collegeId],
    );
  }
}
