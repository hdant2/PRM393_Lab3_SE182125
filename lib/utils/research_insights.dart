import '../models/research_insight.dart';
import '../models/openalex_ranked_entity.dart';
import '../models/publication.dart';
import 'count_format.dart';

class ResearchInsights {
  static TrendInsight analyzeTrend({
    required Map<int, int> volumeByYear,
    Map<int, int>? citationsByYear,
    String? topicLabel,
  }) {
    if (volumeByYear.length < 2) return TrendInsight.empty;

    final years = volumeByYear.keys.toList()..sort();
    final startYear = years.first;
    final endYear = years.last;
    final startCount = volumeByYear[startYear] ?? 0;
    final endCount = volumeByYear[endYear] ?? 0;

    final periodGrowth = _percentChange(startCount, endCount);
    final yoyGrowth = years.length >= 2
        ? _percentChange(
            volumeByYear[years[years.length - 2]] ?? 0,
            volumeByYear[years.last] ?? 0,
          )
        : 0.0;

    final annualRates = <double>[];
    for (var i = 1; i < years.length; i++) {
      final prev = volumeByYear[years[i - 1]] ?? 0;
      final curr = volumeByYear[years[i]] ?? 0;
      if (prev > 0) annualRates.add(_percentChange(prev, curr));
    }
    final avgAnnual = annualRates.isEmpty
        ? 0.0
        : annualRates.reduce((a, b) => a + b) / annualRates.length;

    final peakEntry = volumeByYear.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    final momentum = _momentumFromRates(annualRates, periodGrowth);
    final label = topicLabel ?? 'Research publications';
    final headline = _headline(
      label: label,
      periodGrowth: periodGrowth,
      startYear: startYear,
      endYear: endYear,
    );
    final summary = _summary(
      label: label,
      periodGrowth: periodGrowth,
      startYear: startYear,
      endYear: endYear,
      peakYear: peakEntry.key,
      momentum: momentum,
    );

    final citationNote = _citationDivergenceNote(
      volumeByYear: volumeByYear,
      citationsByYear: citationsByYear,
      years: years,
    );

    return TrendInsight(
      periodGrowthPercent: periodGrowth,
      yoyGrowthPercent: yoyGrowth,
      avgAnnualGrowthPercent: avgAnnual,
      peakYear: peakEntry.key,
      startYear: startYear,
      endYear: endYear,
      momentum: momentum,
      headline: headline,
      summary: summary,
      citationNote: citationNote,
    );
  }

  static double computeConceptGrowth(Map<int, int> yearlyTrend) {
    if (yearlyTrend.length < 2) return 0;

    final years = yearlyTrend.keys.toList()..sort();
    if (years.length < 4) {
      final first = yearlyTrend[years.first] ?? 0;
      final last = yearlyTrend[years.last] ?? 0;
      return _percentChange(first, last);
    }

    final mid = years.length ~/ 2;
    final earlyYears = years.sublist(0, mid);
    final lateYears = years.sublist(mid);

    final earlySum = earlyYears.fold<int>(
      0,
      (sum, year) => sum + (yearlyTrend[year] ?? 0),
    );
    final lateSum = lateYears.fold<int>(
      0,
      (sum, year) => sum + (yearlyTrend[year] ?? 0),
    );

    return _percentChange(earlySum, lateSum);
  }

  static LandscapePulse buildLandscapePulse({
    required int totalPublications,
    required Map<int, int> volumeByYear,
    required double averageCitations,
  }) {
    final insight = analyzeTrend(volumeByYear: volumeByYear);
    return LandscapePulse(
      totalPublications: totalPublications,
      yoyGrowthPercent: insight.yoyGrowthPercent,
      peakYear: insight.peakYear,
      averageCitations: averageCitations,
      summary: insight.summary,
    );
  }

  static TopicSnapshot buildTopicSnapshot({
    required String topic,
    required int totalPublications,
    required Map<int, int> volumeByYear,
    required Map<int, int> citationsByYear,
    OpenAlexRankedEntity? topJournal,
  }) {
    final insight = analyzeTrend(
      volumeByYear: volumeByYear,
      citationsByYear: citationsByYear,
      topicLabel: topic,
    );

    return TopicSnapshot(
      topic: topic,
      totalPublications: totalPublications,
      growthPercent: insight.periodGrowthPercent,
      peakYear: insight.peakYear,
      topJournal: topJournal?.name,
      momentum: insight.momentum,
      insightLine: insight.headline,
    );
  }

  static String influentialPapersInsight(List<Publication> papers) {
    if (papers.isEmpty) {
      return 'Influential papers will appear once OpenAlex data loads.';
    }
    final top = papers.first;
    if (top.citations >= 50000) {
      return 'Landmark papers with ${formatOpenAlexCount(top.citations)}+ citations shape this research landscape.';
    }
    return 'Citation leaders in ${top.journal} drive impact in this field.';
  }

  static String researchLeadersInsight(List<OpenAlexRankedEntity> authors) {
    if (authors.isEmpty) {
      return 'Leading researchers appear after OpenAlex aggregates load.';
    }
    final leader = authors.first;
    return '${leader.name} leads with ${formatOpenAlexCount(leader.count)} publications in this scope.';
  }

  static String journalPowerInsight(List<OpenAlexRankedEntity> journals) {
    if (journals.isEmpty) {
      return 'Top publishing venues will appear from OpenAlex rankings.';
    }
    if (journals.length == 1) {
      return '${journals.first.name} is the dominant publishing venue in this landscape.';
    }
    return '${journals.first.name} and ${journals[1].name} publish the highest volume of influential research.';
  }

  static String formatGrowth(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.round()}%';
  }

  static double _percentChange(int from, int to) {
    if (from <= 0) return to > 0 ? 100 : 0;
    return ((to - from) / from) * 100;
  }

  static MomentumLevel _momentumFromRates(
    List<double> annualRates,
    double periodGrowth,
  ) {
    if (annualRates.isEmpty) {
      if (periodGrowth >= 40) return MomentumLevel.high;
      if (periodGrowth >= 10) return MomentumLevel.medium;
      if (periodGrowth < 0) return MomentumLevel.declining;
      return MomentumLevel.low;
    }

    final recent = annualRates.length >= 3
        ? annualRates.sublist(annualRates.length - 3)
        : annualRates;
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;

    if (recentAvg >= 25 || periodGrowth >= 80) return MomentumLevel.high;
    if (recentAvg >= 5 || periodGrowth >= 20) return MomentumLevel.medium;
    if (recentAvg < -5 || periodGrowth < 0) return MomentumLevel.declining;
    return MomentumLevel.low;
  }

  static String _headline({
    required String label,
    required double periodGrowth,
    required int startYear,
    required int endYear,
  }) {
    if (periodGrowth >= 50) {
      return '$label grew ${formatGrowth(periodGrowth)} from $startYear to $endYear, signaling strong research momentum.';
    }
    if (periodGrowth >= 0) {
      return '$label shows steady growth (${formatGrowth(periodGrowth)}) between $startYear and $endYear.';
    }
    return '$label cooled ${formatGrowth(periodGrowth)} from $startYear to $endYear.';
  }

  static String _summary({
    required String label,
    required double periodGrowth,
    required int startYear,
    required int endYear,
    required int peakYear,
    required MomentumLevel momentum,
  }) {
    final momentumText = switch (momentum) {
      MomentumLevel.high => 'Growth remains strong.',
      MomentumLevel.medium => 'Growth is moderate but sustained.',
      MomentumLevel.low => 'Growth has slowed recently.',
      MomentumLevel.declining => 'Activity is contracting.',
    };

    return 'Publications changed ${formatGrowth(periodGrowth)} between $startYear and $endYear. '
        'Research activity peaked in $peakYear. $momentumText';
  }

  static String? _citationDivergenceNote({
    required Map<int, int> volumeByYear,
    Map<int, int>? citationsByYear,
    required List<int> years,
  }) {
    if (citationsByYear == null || citationsByYear.length < 2) return null;

    final volStart = volumeByYear[years.first] ?? 0;
    final volEnd = volumeByYear[years.last] ?? 0;
    final citeStart = citationsByYear[years.first] ?? 0;
    final citeEnd = citationsByYear[years.last] ?? 0;

    final volGrowth = _percentChange(volStart, volEnd);
    final citeGrowth = _percentChange(citeStart, citeEnd);

    if (volGrowth > 15 && citeGrowth < 0) {
      return 'Paper volume is rising faster than citations — possible quantity inflation in this field.';
    }
    if (volGrowth < 10 && citeGrowth > 25) {
      return 'Fewer papers but rising citations — a high-quality, high-impact research signal.';
    }
    if (volGrowth > 20 && citeGrowth > 20) {
      return 'Both publication volume and citation impact are growing together.';
    }
    return null;
  }
}
