import 'package:flutter/material.dart';

class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  final List<Map<String, String>> _sampleAssignments = const [
    {'title': 'Data Structures Lab Report #3', 'subject': 'Data Structures', 'dueDate': 'Aug 10, 2026', 'status': 'Pending'},
    {'title': 'SQL Query Optimization Problem Set', 'subject': 'Database Systems', 'dueDate': 'Aug 12, 2026', 'status': 'In Progress'},
    {'title': 'Subnetting & Routing Exercise', 'subject': 'Computer Networks', 'dueDate': 'Aug 15, 2026', 'status': 'Completed'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _sampleAssignments.length,
        itemBuilder: (context, index) {
          final item = _sampleAssignments[index];
          final isCompleted = item['status'] == 'Completed';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                isCompleted ? Icons.check_circle : Icons.assignment_outlined,
                color: isCompleted ? Colors.emerald : Colors.amber,
              ),
              title: Text(
                item['title']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text('${item['subject']} • Due: ${item['dueDate']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.emerald.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.emerald : Colors.amber,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
