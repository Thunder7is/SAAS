import 'package:flutter/material.dart';
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/rule_config.dart';
import '../../../domain/models/subject.dart';
import '../../../domain/usecases/attendance_analytics_engine.dart';
import '../../../domain/usecases/attendance_rule_engine.dart';
import '../../../domain/usecases/sync_manager.dart';
import '../../widgets/sync_status_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedPolicyIndex = 0;

  @override
  void initState() {
    super.initState();
    SyncManager.instance.initialize(collegeId: 'SAAS_COLLEGE');
  }

  final List<Subject> _sampleSubjects = const [
    Subject(id: 1, name: 'Data Structures & Algorithms', collegeId: 'SAAS_COLLEGE'),
    Subject(id: 2, name: 'Database Management Systems', collegeId: 'SAAS_COLLEGE'),
    Subject(id: 3, name: 'Computer Networks', collegeId: 'SAAS_COLLEGE'),
    Subject(id: 4, name: 'Software Engineering', collegeId: 'SAAS_COLLEGE'),
  ];

  final List<RuleConfig> _policies = [
    const RuleConfig(
      collegeId: 'SAAS_COLLEGE',
      thresholdPct: 75.0,
      calculationMode: 'per_subject',
      excludedStatuses: ['cancelled'],
      labWeightMultiplier: 1.0,
      perSubjectWeighting: {},
    ),
    const RuleConfig(
      collegeId: 'SAAS_COLLEGE',
      thresholdPct: 75.0,
      calculationMode: 'aggregate',
      excludedStatuses: ['cancelled', 'medical_leave'],
      labWeightMultiplier: 2.0,
      perSubjectWeighting: {},
    ),
    const RuleConfig(
      collegeId: 'SAAS_COLLEGE',
      thresholdPct: 80.0,
      calculationMode: 'per_subject',
      excludedStatuses: ['cancelled', 'duty_leave'],
      labWeightMultiplier: 1.5,
      perSubjectWeighting: {'Data Structures & Algorithms': 2.0},
    ),
  ];

  final List<AttendanceRecord> _sampleRecords = [
    AttendanceRecord(id: 1, subjectId: 1, date: DateTime(2026, 8, 1), status: AttendanceStatus.present, isLab: true, source: RecordSource.imported),
    AttendanceRecord(id: 2, subjectId: 1, date: DateTime(2026, 8, 2), status: AttendanceStatus.present, isLab: false, source: RecordSource.imported),
    AttendanceRecord(id: 3, subjectId: 1, date: DateTime(2026, 8, 3), status: AttendanceStatus.medicalLeave, isLab: false, source: RecordSource.imported),
    AttendanceRecord(id: 4, subjectId: 1, date: DateTime(2026, 8, 4), status: AttendanceStatus.present, isLab: true, source: RecordSource.manual),

    AttendanceRecord(id: 5, subjectId: 2, date: DateTime(2026, 8, 1), status: AttendanceStatus.present, isLab: false, source: RecordSource.imported),
    AttendanceRecord(id: 6, subjectId: 2, date: DateTime(2026, 8, 2), status: AttendanceStatus.present, isLab: false, source: RecordSource.imported),
    AttendanceRecord(id: 7, subjectId: 2, date: DateTime(2026, 8, 4), status: AttendanceStatus.present, isLab: false, source: RecordSource.manual),

    AttendanceRecord(id: 8, subjectId: 3, date: DateTime(2026, 8, 1), status: AttendanceStatus.present, isLab: false, source: RecordSource.imported),
    AttendanceRecord(id: 9, subjectId: 3, date: DateTime(2026, 8, 2), status: AttendanceStatus.absent, isLab: false, source: RecordSource.imported),
    AttendanceRecord(id: 10, subjectId: 3, date: DateTime(2026, 8, 4), status: AttendanceStatus.absent, isLab: false, source: RecordSource.manual),
  ];

  void _showMarkTodayDialog() {
    Subject? selectedSubject = _sampleSubjects.first;
    AttendanceStatus selectedStatus = AttendanceStatus.present;
    bool isLab = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit_calendar, color: Colors.indigoAccent),
                  SizedBox(width: 8),
                  Text('Mark Today\'s Attendance'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Subject:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<Subject>(
                    value: selectedSubject,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    items: _sampleSubjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedSubject = val),
                  ),
                  const SizedBox(height: 16),
                  const Text('Attendance Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<AttendanceStatus>(
                    value: selectedStatus,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    items: const [
                      DropdownMenuItem(value: AttendanceStatus.present, child: Text('Present')),
                      DropdownMenuItem(value: AttendanceStatus.absent, child: Text('Absent')),
                      DropdownMenuItem(value: AttendanceStatus.medicalLeave, child: Text('Medical Leave')),
                      DropdownMenuItem(value: AttendanceStatus.dutyLeave, child: Text('Duty Leave')),
                    ],
                    onChanged: (val) => setModalState(() => selectedStatus = val!),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Is Practical / Lab Session?'),
                    value: isLab,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setModalState(() => isLab = val ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedSubject != null) {
                      setState(() {
                        _sampleRecords.add(AttendanceRecord(
                          id: DateTime.now().millisecondsSinceEpoch,
                          subjectId: selectedSubject!.id!,
                          date: DateTime.now(),
                          status: selectedStatus,
                          isLab: isLab,
                          source: RecordSource.manual,
                        ));
                      });
                    }
                    Navigator.pop(context);
                    SyncManager.instance.triggerSync(); // Queue & sync immediately
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Marked today\'s attendance for ${selectedSubject?.name} (Source: Manual)')),
                    );
                  },
                  child: const Text('Save Entry'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSubjectDetail(Subject subject, SubjectAttendanceDetail detail) {
    final subjectRecords = _sampleRecords.where((r) => r.subjectId == subject.id).toList();
    final analytics = detail.analytics;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subject.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildRiskBadge(analytics),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('Current Attendance', '${analytics.currentPercentage}%'),
                            _buildStatColumn('Classes Held', '${analytics.totalClassesHeld}'),
                            _buildStatColumn('Attended', '${analytics.attendedClasses}'),
                          ],
                        ),
                        const Divider(height: 24),

                        if (analytics.isBelowThreshold) ...[
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  analytics.isRecoverable
                                      ? 'Needs ${analytics.recoveryCount} consecutive lecture(s) to recover to ${analytics.thresholdPct}%'
                                      : 'Attendance shortage is unrecoverable (100% target)',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  analytics.safeBunkCount > 0
                                      ? 'Safe to bunk ${analytics.safeBunkCount} upcoming class(es) while staying above ${analytics.thresholdPct}%'
                                      : 'At margin: bunking next class will drop attendance below ${analytics.thresholdPct}%',
                                  style: TextStyle(
                                    color: analytics.safeBunkCount > 0 ? Colors.green : Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Full Attendance History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (subjectRecords.isEmpty)
                    const Text('No attendance records logged yet.')
                  else
                    ...subjectRecords.map((record) {
                      final statusStr = record.status.toValue().toUpperCase();
                      final isPresent = record.status == AttendanceStatus.present;
                      final isManual = record.source == RecordSource.manual;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            isPresent ? Icons.check_circle : Icons.cancel,
                            color: isPresent ? Colors.green : Colors.red,
                          ),
                          title: Row(
                            children: [
                              Text(
                                '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isManual ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isManual ? 'MANUAL' : 'IMPORTED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isManual ? Colors.orange : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(record.isLab ? 'Session: Lab (Weighted)' : 'Session: Theory'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPresent ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statusStr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPresent ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRiskBadge(SubjectAnalyticsResult analytics) {
    String label;
    Color color;

    if (analytics.isBelowThreshold) {
      label = 'CRITICAL';
      color = Colors.red;
    } else if (analytics.safeBunkCount == 0 || analytics.currentPercentage < analytics.thresholdPct + 5.0) {
      label = 'WARNING';
      color = Colors.amber;
    } else {
      label = 'SAFE';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = _policies[_selectedPolicyIndex];
    final result = AttendanceRuleEngine.calculate(
      records: _sampleRecords,
      subjects: _sampleSubjects,
      config: activeConfig,
    );

    final policyTitles = ['Strict Standard (75%)', 'Flexible Medical (75%)', 'Weighted Core (80%)'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: SyncStatusIndicator(), // Visible Sync Status Indicator Widget
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMarkTodayDialog,
        icon: const Icon(Icons.check_box_outlined),
        label: const Text('Mark Today'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'College Attendance Policy:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(policyTitles.length, (index) {
                  final isSelected = index == _selectedPolicyIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(policyTitles[index]),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedPolicyIndex = index);
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Attendance',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${result.aggregatePercentage}%',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: result.isOverallCompliant
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                result.isOverallCompliant
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                color: result.isOverallCompliant ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                result.isOverallCompliant ? 'Compliant' : 'Shortage Risk',
                                style: TextStyle(
                                  color: result.isOverallCompliant ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (result.aggregatePercentage / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      color: result.aggregatePercentage >= activeConfig.thresholdPct
                          ? Colors.indigoAccent
                          : Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mode: ${activeConfig.calculationMode.toUpperCase()}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Threshold: ${activeConfig.thresholdPct}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Subjects Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tap subject for details',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sampleSubjects.length,
              itemBuilder: (context, index) {
                final subject = _sampleSubjects[index];
                final detail = result.subjectDetails[subject.id!];

                if (detail == null) return const SizedBox.shrink();

                final analytics = detail.analytics;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showSubjectDetail(subject, detail),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  subject.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildRiskBadge(analytics),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '${analytics.currentPercentage}%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: analytics.isBelowThreshold ? Colors.red : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attended ${detail.attendedClasses} / ${detail.totalClasses} sessions',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      analytics.isBelowThreshold
                                          ? 'Shortage: Need ${analytics.recoveryCount} recovery class(es)'
                                          : (analytics.safeBunkCount > 0
                                              ? 'Safe to bunk: ${analytics.safeBunkCount} class(es)'
                                              : 'Safe to bunk: 0 classes'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: analytics.isBelowThreshold
                                            ? Colors.redAccent
                                            : (analytics.safeBunkCount > 0 ? Colors.green : Colors.amber),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
