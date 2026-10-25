import '../models/column_mapping.dart';

abstract class ColumnMappingRepository {
  Future<ColumnMapping?> getColumnMapping(String collegeId);
  Future<int> saveColumnMapping(ColumnMapping mapping);
  Future<int> deleteColumnMapping(String collegeId);
}
