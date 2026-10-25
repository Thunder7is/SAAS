import 'package:flutter/material.dart';
import '../../../domain/models/timetable_entry.dart';
import '../../../domain/usecases/timetable_import_engine.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _days = const ['Today', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  final List<TimetableEntry> _entries = [
    const TimetableEntry(id: 1, subjectId: 1, subjectName: 'Data Structures & Algorithms', dayOfWeek: 'Monday', startTime: '09:00 AM', endTime: '10:30 AM', room: 'Lab 3', isLab: true),
    const TimetableEntry(id: 2, subjectId: 2, subjectName: 'Database Management Systems', dayOfWeek: 'Monday', startTime: '11:00 AM', endTime: '12:30 PM', room: 'Hall B', isLab: false),
    const TimetableEntry(id: 3, subjectId: 3, subjectName: 'Computer Networks', dayOfWeek: 'Tuesday', startTime: '09:00 AM', endTime: '10:30 AM', room: 'Room 102', isLab: false),
    const TimetableEntry(id: 4, subjectId: 1, subjectName: 'Data Structures & Algorithms', dayOfWeek: 'Tuesday', startTime: '02:00 PM', endTime: '04:00 PM', room: 'Lab 3', isLab: true),
    const TimetableEntry(id: 5, subjectId: 4, subjectName: 'Software Engineering', dayOfWeek: 'Wednesday', startTime: '09:00 AM', endTime: '10:30 AM', room: 'Hall A', isLab: false),
    const TimetableEntry(id: 6, subjectId: 2, subjectName: 'Database Management Systems', dayOfWeek: 'Thursday', startTime: '10:00 AM', endTime: '11:30 AM', room: 'Room 204', isLab: false),
    const TimetableEntry(id: 7, subjectId: 3, subjectName: 'Computer Networks', dayOfWeek: 'Friday', startTime: '11:00 AM', endTime: '12:30 PM', room: 'Lab 1', isLab: true),
  ];

  final String _sampleTimetableCsv = '''Subject, Day, Start Time, End Time, Room
Data Structures & Algorithms, Monday, 09:00 AM, 10:30 AM, Lab 3
Database Systems, Monday, 11:00 AM, 12:30 PM, Hall B
Computer Networks, Tuesday, 09:00 AM, 10:30 AM, Room 102
Software Engineering, Wednesday, 09:00 AM, 10:30 AM, Hall A''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTodayName() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      default:
        return 'Sunday';
    }
  }

  void _showAddEntryDialog() {
    String subjectName = 'Data Structures & Algorithms';
    String day = _getTodayName();
    String startTime = '09:00 AM';
    String endTime = '10:30 AM';
    String room = 'Room 101';
    bool isLab = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add Timetable Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: subjectName,
                      decoration: const InputDecoration(labelText: 'Subject Name', border: OutlineInputBorder()),
                      onChanged: (val) => subjectName = val,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: day,
                      decoration: const InputDecoration(labelText: 'Day of Week', border: OutlineInputBorder()),
                      items: const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) => setModalState(() => day = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: startTime,
                            decoration: const InputDecoration(labelText: 'Start Time', border: OutlineInputBorder()),
                            onChanged: (val) => startTime = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: endTime,
                            decoration: const InputDecoration(labelText: 'End Time', border: OutlineInputBorder()),
                            onChanged: (val) => endTime = val,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: room,
                      decoration: const InputDecoration(labelText: 'Room / Venue', border: OutlineInputBorder()),
                      onChanged: (val) => room = val,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Is Practical / Lab?'),
                      value: isLab,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setModalState(() => isLab = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _entries.add(TimetableEntry(
                        id: DateTime.now().millisecondsSinceEpoch,
                        subjectId: 1,
                        subjectName: subjectName,
                        dayOfWeek: day,
                        startTime: startTime,
                        endTime: endTime,
                        room: room,
                        isLab: isLab,
                      ));
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added timetable entry for $subjectName')),
                    );
                  },
                  child: const Text('Save Slot'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCsvImportDialog() {
    final result = TimetableImportEngine.processCsv(
      csvText: _sampleTimetableCsv,
      subjectNameToIdMap: {'Data Structures & Algorithms': 1, 'Database Systems': 2, 'Computer Networks': 3},
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timetable CSV Import'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parsed ${result.totalRowsProcessed} rows from timetable CSV.'),
            Text('Successfully created: ${result.successfulRows} class slots.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _entries.addAll(result.entries);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Imported timetable entries successfully!')),
              );
            },
            child: const Text('Import Slots'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(TimetableEntry item, {bool isToday = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      item.isLab ? Icons.science_outlined : Icons.menu_book_outlined,
                      color: item.isLab ? Colors.purpleAccent : Colors.indigoAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.startTime,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(' - ${item.endTime}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.room,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.subjectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (isToday)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                    label: const Text('Mark Absent', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked Absent for ${item.subjectName}')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Mark Present', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked Present for ${item.subjectName}')),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayName = _getTodayName();
    final todayEntries = _entries.where((e) => e.dayOfWeek.toLowerCase() == todayName.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable & Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import CSV',
            onPressed: _showCsvImportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Slot',
            onPressed: _showAddEntryDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((d) => Tab(text: d)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days.map((day) {
          List<TimetableEntry> dayList;
          bool isTodayTab = day == 'Today';

          if (isTodayTab) {
            dayList = todayEntries;
          } else {
            dayList = _entries.where((e) => e.dayOfWeek.toLowerCase() == day.toLowerCase()).toList();
          }

          if (dayList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_seat_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    isTodayTab ? 'No classes scheduled for Today ($todayName)!' : 'No classes scheduled for $day.',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: dayList.length,
            itemBuilder: (context, index) {
              return _buildClassCard(dayList[index], isToday: isTodayTab);
            },
          );
        }).toList(),
      ),
    );
  }
}
