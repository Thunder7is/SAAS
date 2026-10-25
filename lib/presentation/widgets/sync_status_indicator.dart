import 'package:flutter/material.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/usecases/sync_manager.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: SyncManager.instance.statusNotifier,
      builder: (context, status, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => SyncManager.instance.triggerSync(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: status.color.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == SyncStatus.syncing)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(status.color),
                    ),
                  )
                else
                  Icon(status.icon, size: 14, color: status.color),
                const SizedBox(width: 6),
                Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: status.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
