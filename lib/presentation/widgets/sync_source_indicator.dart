import 'package:flutter/material.dart';
import '../../domain/models/college_sync_metadata.dart';

class SyncSourceIndicator extends StatelessWidget {
  final CollegeSyncMetadata metadata;
  final VoidCallback onSwitchToManual;

  const SyncSourceIndicator({
    super.key,
    required this.metadata,
    required this.onSwitchToManual,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: metadata.source.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: metadata.source.color.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    metadata.source == CollegeSyncSource.autoScrape
                        ? Icons.sync_desktop
                        : Icons.description_outlined,
                    size: 12,
                    color: metadata.source.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Source: ${metadata.source.label}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: metadata.source.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Prompts user when auto-scrape has failed N (>= 3) times in a row
        if (metadata.needsManualFallback) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-scrape failed ${metadata.consecutiveFailures} times in a row',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Switch to manual CSV import without losing any previously synced data?',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onSwitchToManual,
                  child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
