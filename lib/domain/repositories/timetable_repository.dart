import '../models/timetable_entry.dart';

abstract class TimetableRepository {
  Future<List<TimetableEntry>> getAllEntries();
  Future<List<TimetableEntry>> getEntriesByDay(String dayOfWeek);
  Future<int> insertEntry(TimetableEntry entry);
  Future<int> updateEntry(TimetableEntry entry);
  Future<int> deleteEntry(int id);
  Future<void> clearAll();
}
