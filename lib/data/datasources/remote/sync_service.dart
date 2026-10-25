import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/rule_config.dart';
import '../../../domain/models/subject.dart';
import '../../../domain/models/sync_status.dart';
import '../../repositories/attendance_repository_impl.dart';
import '../../repositories/rule_config_repository_impl.dart';
import '../../repositories/subject_repository_impl.dart';

class SyncService {
  final String baseUrl;
  final SubjectRepositoryImpl subjectRepo;
  final AttendanceRepositoryImpl attendanceRepo;
  final RuleConfigRepositoryImpl ruleConfigRepo;
  
  String? authToken;
  String? lastSyncToken;

  SyncService({
    this.baseUrl = 'http://localhost:8000/api/v1',
    SubjectRepositoryImpl? subjectRepository,
    AttendanceRepositoryImpl? attendanceRepository,
    RuleConfigRepositoryImpl? ruleConfigRepository,
  })  : subjectRepo = subjectRepository ?? SubjectRepositoryImpl(),
        attendanceRepo = attendanceRepository ?? AttendanceRepositoryImpl(),
        ruleConfigRepo = ruleConfigRepository ?? RuleConfigRepositoryImpl();

  /// Push local changes then pull remote changes, merging into local SQLite store
  Future<SyncStatus> performSync(String collegeId) async {
    try {
      // 1. Fetch un-synced local data
      final localSubjects = await subjectRepo.getSubjectsByCollege(collegeId);
      final localAttendance = await attendanceRepo.getAllRecords();
      final localRuleConfig = await ruleConfigRepo.getRuleConfigByCollege(collegeId);

      // Construct Push payload
      final Map<String, dynamic> pushPayload = {
        'subjects': localSubjects.map((s) => {
          if (s.id != null) 'id': s.id,
          'name': s.name,
          'college_id': s.collegeId,
          'updated_at': DateTime.now().toIso8601String(),
        }).toList(),
        'attendance_records': localAttendance.map((a) => {
          if (a.id != null) 'id': a.id,
          'subject_id': a.subjectId,
          'date': a.date.toIso8601String().split('T')[0],
          'status': a.status.toValue(),
          'is_lab': a.isLab,
          'source': a.source.toValue(),
          'updated_at': DateTime.now().toIso8601String(),
        }).toList(),
        'rule_config': localRuleConfig != null ? {
          'college_id': localRuleConfig.collegeId,
          'threshold_pct': localRuleConfig.thresholdPct,
          'calculation_mode': localRuleConfig.calculationMode,
          'excluded_statuses': localRuleConfig.excludedStatuses,
          'lab_weight_multiplier': localRuleConfig.labWeightMultiplier,
          'per_subject_weighting': localRuleConfig.perSubjectWeighting,
          'updated_at': DateTime.now().toIso8601String(),
        } : null,
        'client_sync_time': DateTime.now().toIso8601String(),
      };

      // 2. Perform HTTP Push
      final pushResponse = await http
          .post(
            Uri.parse('$baseUrl/sync/push'),
            headers: {
              'Content-Type': 'application/json',
              if (authToken != null) 'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(pushPayload),
          )
          .timeout(const Duration(seconds: 10));

      if (pushResponse.statusCode == 200) {
        final pushBody = jsonDecode(pushResponse.body);
        lastSyncToken = pushBody['new_sync_token'];
      }

      // 3. Perform HTTP Pull
      String pullUrl = '$baseUrl/sync/pull';
      if (lastSyncToken != null) {
        pullUrl += '?last_sync_token=${Uri.encodeComponent(lastSyncToken!)}';
      }

      final pullResponse = await http
          .get(
            Uri.parse(pullUrl),
            headers: {
              if (authToken != null) 'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (pullResponse.statusCode == 200) {
        final pullBody = jsonDecode(pullResponse.body);
        lastSyncToken = pullBody['new_sync_token'];

        // Merge remote subjects into SQLite
        final List remoteSubjects = pullBody['subjects'] ?? [];
        for (var sMap in remoteSubjects) {
          final subject = Subject(
            id: sMap['id'],
            name: sMap['name'],
            collegeId: sMap['college_id'],
          );
          await subjectRepo.insertSubject(subject);
        }

        // Merge remote attendance records into SQLite
        final List remoteRecords = pullBody['attendance_records'] ?? [];
        for (var rMap in remoteRecords) {
          final record = AttendanceRecord(
            id: rMap['id'],
            subjectId: rMap['subject_id'],
            date: DateTime.parse(rMap['date']),
            status: AttendanceStatus.fromValue(rMap['status']),
            isLab: rMap['is_lab'] ?? false,
            source: RecordSource.fromValue(rMap['source']),
          );
          await attendanceRepo.insertRecord(record);
        }

        return SyncStatus.synced;
      }
      return SyncStatus.offline;
    } on SocketException catch (_) {
      // Offline: network unavailable
      return SyncStatus.offline;
    } on TimeoutException catch (_) {
      return SyncStatus.offline;
    } catch (_) {
      return SyncStatus.offline;
    }
  }
}
