import '../../domain/models/subject.dart';
import '../../domain/repositories/subject_repository.dart';
import '../datasources/local/database_helper.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  final DatabaseHelper dbHelper;

  SubjectRepositoryImpl({DatabaseHelper? helper})
      : dbHelper = helper ?? DatabaseHelper.instance;

  @override
  Future<List<Subject>> getSubjectsByCollege(String collegeId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'subjects',
      where: 'college_id = ?',
      whereArgs: [collegeId],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Subject.fromMap(m)).toList();
  }

  @override
  Future<Subject?> getSubjectById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Subject.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> insertSubject(Subject subject) async {
    final db = await dbHelper.database;
    return await db.insert('subjects', subject.toMap());
  }

  @override
  Future<int> updateSubject(Subject subject) async {
    final db = await dbHelper.database;
    return await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  @override
  Future<int> deleteSubject(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
