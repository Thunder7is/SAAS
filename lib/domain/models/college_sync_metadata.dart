import 'package:flutter/material.dart';

enum CollegeSyncSource {
  autoScrape,
  manualCsv;

  String get label {
    switch (this) {
      case CollegeSyncSource.autoScrape:
        return 'Auto-Scrape';
      case CollegeSyncSource.manualCsv:
        return 'Manual CSV';
    }
  }

  Color get color {
    switch (this) {
      case CollegeSyncSource.autoScrape:
        return Colors.blue;
      case CollegeSyncSource.manualCsv:
        return Colors.green;
    }
  }
}

class CollegeSyncMetadata {
  final String collegeId;
  final CollegeSyncSource source;
  final int consecutiveFailures;
  final DateTime? lastScrapeTime;

  const CollegeSyncMetadata({
    required this.collegeId,
    this.source = CollegeSyncSource.autoScrape,
    this.consecutiveFailures = 0,
    this.lastScrapeTime,
  });

  bool get needsManualFallback => consecutiveFailures >= 3 && source == CollegeSyncSource.autoScrape;

  CollegeSyncMetadata copyWith({
    String? collegeId,
    CollegeSyncSource? source,
    int? consecutiveFailures,
    DateTime? lastScrapeTime,
  }) {
    return CollegeSyncMetadata(
      collegeId: collegeId ?? this.collegeId,
      source: source ?? this.source,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastScrapeTime: lastScrapeTime ?? this.lastScrapeTime,
    );
  }
}
