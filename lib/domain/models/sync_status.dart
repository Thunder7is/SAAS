import 'package:flutter/material.dart';

enum SyncStatus {
  synced,
  syncing,
  offline;

  String get label {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline';
    }
  }

  Color get color {
    switch (this) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.offline:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.offline:
        return Icons.cloud_off;
    }
  }
}
