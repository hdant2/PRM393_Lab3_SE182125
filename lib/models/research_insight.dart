// =============================================================================
// research_insight.dart — MODEL CHO INSIGHT / SNAPSHOT UI
// =============================================================================
// Các class này là KẾT QUẢ TÍNH TOÁN từ ResearchInsights + provider,
// không parse trực tiếp từ JSON OpenAlex.
// =============================================================================

/// Mức độ momentum hiển thị badge HIGH / MEDIUM / LOW / DECLINING
enum MomentumLevel {
  high,
  medium,
  low,
  declining,
}

extension MomentumLevelX on MomentumLevel {
  String get label {
    switch (this) {
      case MomentumLevel.high:
        return 'HIGH';
      case MomentumLevel.medium:
        return 'MEDIUM';
      case MomentumLevel.low:
        return 'LOW';
      case MomentumLevel.declining:
        return 'DECLINING';
    }
  }
}

/// Kết quả phân tích trend theo năm (Analytics, Growth screen)
class TrendInsight {
  final double periodGrowthPercent;
  final double yoyGrowthPercent;
  final double avgAnnualGrowthPercent;
  final int peakYear;
  final int startYear;
  final int endYear;
  final MomentumLevel momentum;
  final String headline;
  final String summary;
  final String? citationNote;

  const TrendInsight({
    required this.periodGrowthPercent,
    required this.yoyGrowthPercent,
    required this.avgAnnualGrowthPercent,
    required this.peakYear,
    required this.startYear,
    required this.endYear,
    required this.momentum,
    required this.headline,
    required this.summary,
    this.citationNote,
  });

  /// Dùng khi chưa đủ dữ liệu trend
  static const empty = TrendInsight(
    periodGrowthPercent: 0,
    yoyGrowthPercent: 0,
    avgAnnualGrowthPercent: 0,
    peakYear: 0,
    startYear: 0,
    endYear: 0,
    momentum: MomentumLevel.low,
    headline: 'Insufficient data',
    summary: 'Not enough OpenAlex data to generate insights.',
  );
}

/// Một concept/domain đang tăng trưởng nhanh (Emerging Topics)
class TopicGrowthInsight {
  final String id;
  final String name;
  final double growthPercent;

  const TopicGrowthInsight({
    required this.id,
    required this.name,
    required this.growthPercent,
  });

  bool get isDeclining => growthPercent < 0;

  /// Hiển thị +280% hoặc -5%
  String get formattedGrowth {
    final sign = growthPercent >= 0 ? '+' : '';
    return '$sign${growthPercent.round()}%';
  }
}

/// Card snapshot sau khi user search topic trên Explore
class TopicSnapshot {
  final String topic;
  final int totalPublications;
  final double growthPercent;
  final int peakYear;
  final String? topJournal;
  final MomentumLevel momentum;
  final String insightLine;

  const TopicSnapshot({
    required this.topic,
    required this.totalPublications,
    required this.growthPercent,
    required this.peakYear,
    this.topJournal,
    required this.momentum,
    required this.insightLine,
  });
}

/// Pulse card trên Overview — tổng publications + YoY + avg citations
class LandscapePulse {
  final int totalPublications;
  final double yoyGrowthPercent;
  final int peakYear;
  final double averageCitations;
  final String summary;

  const LandscapePulse({
    required this.totalPublications,
    required this.yoyGrowthPercent,
    required this.peakYear,
    required this.averageCitations,
    required this.summary,
  });
}
