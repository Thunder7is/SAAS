import '../models/subject.dart';

abstract class SubjectRepository {
  Future<List<Subject>> getSubjectsByCollege(String collegeId);
  Future<Subject?> getSubjectById(int id);
  Future<int> insertSubject(Subject subject);
  Future<int> updateSubject(Subject subject);
  Future<int> deleteSubject(int id);
}
