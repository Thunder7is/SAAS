import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sync_status.dart';
import '../../data/datasources/remote/sync_service.dart';

class SyncManager with WidgetsBindingObserver {
  static final SyncManager instance = SyncManager._init();

  final SyncService _syncService = SyncService();
  final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier<SyncStatus>(SyncStatus.synced);
  final ValueNotifier<DateTime?> lastSyncedNotifier = ValueNotifier<DateTime?>(null);

  Timer? _periodicTimer;
  bool _isSyncing = false;
  String _collegeId = 'SAAS_COLLEGE';

  SyncManager._init();

  void initialize({String collegeId = 'SAAS_COLLEGE'}) {
    _collegeId = collegeId;
    WidgetsBinding.instance.addObserver(this);
    
    // Start periodic background timer (every 5 minutes)
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      triggerSync();
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground -> Trigger sync!
      triggerSync();
    }
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    statusNotifier.value = SyncStatus.syncing;

    try {
      final resultStatus = await _syncService.performSync(_collegeId);
      statusNotifier.value = resultStatus;
      if (resultStatus == SyncStatus.synced) {
        lastSyncedNotifier.value = DateTime.now();
      }
    } catch (_) {
      statusNotifier.value = SyncStatus.offline;
    } finally {
      _isSyncing = false;
    }
  }
}
