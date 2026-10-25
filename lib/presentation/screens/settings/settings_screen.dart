import 'package:flutter/material.dart';
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/college_sync_metadata.dart';
import '../../../domain/models/column_mapping.dart';
import '../../../domain/usecases/file_import_engine.dart';
import '../../../domain/usecases/reconciliation_engine.dart';
import '../../widgets/sync_source_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCollegeId = 'SAAS_COLLEGE';
  double _thresholdPct = 75.0;
  String _calculationMode = 'per_subject';

  CollegeSyncMetadata _syncMetadata = const CollegeSyncMetadata(
    collegeId: 'SAAS_COLLEGE',
    source: CollegeSyncSource.autoScrape,
    consecutiveFailures: 3, // Simulated 3 consecutive auto-scrape failures
  );

  final List<AttendanceRecord> _existingLocalRecords = [
    AttendanceRecord(
      id: 101,
      subjectId: 1,
      date: DateTime(2026, 8, 4),
      status: AttendanceStatus.present,
      source: RecordSource.manual,
    ),
  ];

  final String _sampleCsvData = '''Course Title, Session Date, Presence Status
Data Structures & Algorithms, 2026-08-04, Present
Database Systems, 2026-08-04, Present''';

  void _showFileImportDialog() {
    final parsed = FileImportEngine.parseCsv(_sampleCsvData);
    final headers = List<String>.from(parsed['headers']);
    final rows = List<List<dynamic>>.from(parsed['rows']);

    ColumnMapping mapping = ColumnMapping.autoGuess(
      collegeId: _selectedCollegeId,
      headers: headers,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('CSV / XLSX Column Mapping'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm column mappings for college: $_selectedCollegeId',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildMappingDropdown('Subject Column', headers, mapping.subjectCol, (val) {
                      setModalState(() {
                        mapping = ColumnMapping(
                          collegeId: mapping.collegeId,
                          subjectCol: val!,
                          dateCol: mapping.dateCol,
                          statusCol: mapping.statusCol,
                          isLabCol: mapping.isLabCol,
                          updatedAt: DateTime.now(),
                        );
                      });
                    }),
                    _buildMappingDropdown('Date Column', headers, mapping.dateCol, (val) {
                      setModalState(() {
                        mapping = ColumnMapping(
                          collegeId: mapping.collegeId,
                          subjectCol: mapping.subjectCol,
                          dateCol: val!,
                          statusCol: mapping.statusCol,
                          isLabCol: mapping.isLabCol,
                          updatedAt: DateTime.now(),
                        );
                      });
                    }),
                    _buildMappingDropdown('Status Column', headers, mapping.statusCol, (val) {
                      setModalState(() {
                        mapping = ColumnMapping(
                          collegeId: mapping.collegeId,
                          subjectCol: mapping.subjectCol,
                          dateCol: mapping.dateCol,
                          statusCol: val!,
                          isLabCol: mapping.isLabCol,
                          updatedAt: DateTime.now(),
                        );
                      });
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final subjectMap = {'Data Structures & Algorithms': 1, 'Database Systems': 2};
                    final importResult = FileImportEngine.processDataRows(
                      headers: headers,
                      rows: rows,
                      mapping: mapping,
                      subjectNameToIdMap: subjectMap,
                    );

                    final reconResult = ReconciliationEngine.reconcile(
                      existingRecords: _existingLocalRecords,
                      incomingRecords: importResult.importedRecords,
                      subjectIdToNameMap: {1: 'Data Structures & Algorithms', 2: 'Database Systems'},
                    );

                    _showImportResultDialog(importResult, reconResult);
                  },
                  child: const Text('Run Import'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMappingDropdown(
      String label, List<String> headers, String selected, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: headers.contains(selected) ? selected : (headers.isNotEmpty ? headers.first : null),
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            items: headers
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showImportResultDialog(importResult, reconResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Processed ${importResult.totalRowsProcessed} rows.'),
            Text('Successfully imported: ${importResult.successfulRows} records.'),
            Text('Auto-reconciled entries: ${reconResult.autoMergedCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'College Sync Source & Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SyncSourceIndicator(
                    metadata: _syncMetadata,
                    onSwitchToManual: () {
                      setState(() {
                        _syncMetadata = _syncMetadata.copyWith(
                          source: CollegeSyncSource.manualCsv,
                          consecutiveFailures: 0,
                        );
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Switched to Manual CSV Import. Existing data preserved.')),
                      );
                      _showFileImportDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Local Storage & Database',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage, color: Colors.indigoAccent),
              title: const Text('SQLite Database Status'),
              subtitle: const Text('Tables: subjects, attendance_records, rule_configs, column_mappings'),
              trailing: const Chip(
                label: Text('Local Only', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.emerald,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'College Policy Config',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum Attendance Threshold:'),
                      Text('${_thresholdPct.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _thresholdPct,
                    min: 50.0,
                    max: 100.0,
                    divisions: 10,
                    label: '${_thresholdPct.toInt()}%',
                    onChanged: (val) => setState(() => _thresholdPct = val),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Calculation Mode:'),
                      DropdownButton<String>(
                        value: _calculationMode,
                        items: const [
                          DropdownMenuItem(value: 'per_subject', child: Text('Per Subject')),
                          DropdownMenuItem(value: 'aggregate', child: Text('Aggregate')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _calculationMode = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'File Import & Reconciliation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.indigoAccent),
              title: const Text('Import Attendance Sheet'),
              subtitle: const Text('CSV/XLSX import with manual entry conflict detection'),
              trailing: ElevatedButton(
                onPressed: _showFileImportDialog,
                child: const Text('Import'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
