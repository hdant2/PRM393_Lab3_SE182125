import 'package:flutter/material.dart';

// [Merge resolved] Chọn feature/lab3: import viewmodels thay vì providers
import '../viewmodels/publication_viewmodel.dart';
import '../screens/year_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/research_insights.dart';
import 'app_logo.dart';
import 'insight_widgets.dart';
import 'trend_chart.dart';

enum TrendMetric {
  publications,
  citationImpact,
  avgCitations,
}

extension TrendMetricX on TrendMetric {
  String get label {
    switch (this) {
      case TrendMetric.publications:
        return 'Publication Volume';
      case TrendMetric.citationImpact:
        return 'Citations';
      case TrendMetric.avgCitations:
        return 'Avg. Citations';
    }
  }
}

/// Trend chart + momentum + yearly breakdown — chỉ dùng khi đã search topic.
class TopicTrendAnalyticsPanel extends StatefulWidget {
  final PublicationViewModel provider;
  final bool compact;

  const TopicTrendAnalyticsPanel({
    super.key,
    required this.provider,
    this.compact = false,
  });

  @override
  State<TopicTrendAnalyticsPanel> createState() =>
      _TopicTrendAnalyticsPanelState();
}

class _TopicTrendAnalyticsPanelState extends State<TopicTrendAnalyticsPanel> {
  TrendMetric _metric = TrendMetric.publications;

  Map<int, int> _dataForMetric(PublicationViewModel provider) {
    switch (_metric) {
      case TrendMetric.publications:
        return provider.yearlyTrendFromOpenAlex;
      case TrendMetric.citationImpact:
        return provider.citationsByYearOpenAlex;
      case TrendMetric.avgCitations:
        return provider.avgCitationsByYearOpenAlex;
    }
  }

  String _metricValueLabel() {
    switch (_metric) {
      case TrendMetric.publications:
        return 'publications';
      case TrendMetric.citationImpact:
        return 'total citations';
      case TrendMetric.avgCitations:
        return 'avg citations';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final topic = provider.currentTopic;
    final loading = provider.isTrendLoading;
    final yearlyData = _dataForMetric(provider);
    final sortedYears = yearlyData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final maxCount = yearlyData.values.isEmpty
        ? 1
        : yearlyData.values.reduce((a, b) => a > b ? a : b);
    final insight = provider.trendInsight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) ...[
          const Text(
            'Publication Trend',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          'Topic: $topic',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<TrendMetric>(
          segments: TrendMetric.values
              .map(
                (m) => ButtonSegment(
                  value: m,
                  label: Text(m.label, style: const TextStyle(fontSize: 11)),
                ),
              )
              .toList(),
          selected: {_metric},
          onSelectionChanged: (value) {
            setState(() => _metric = value.first);
          },
        ),
        const SizedBox(height: 16),
        Text(
          '${_metric.label} Over Time',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        if (loading && yearlyData.isEmpty)
          const MockupCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          )
        else if (yearlyData.isEmpty)
          const Text(
            'No trend data for this topic yet.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          MockupCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: TrendChart(
              yearlyData: yearlyData,
              overlayYearlyData: _metric == TrendMetric.publications
                  ? provider.citationsByYearOpenAlex
                  : null,
            ),
          ),
        if (!widget.compact && yearlyData.isNotEmpty) ...[
          const SizedBox(height: 16),
          MockupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Research Momentum',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    MomentumBadge(level: insight.momentum),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ResearchInsights.formatGrowth(insight.periodGrowthPercent),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Publication volume growth · $topic',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Annual Growth',
                        value: ResearchInsights.formatGrowth(
                          insight.avgAnnualGrowthPercent,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Peak Year',
                        value: '${insight.peakYear}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  insight.headline,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Yearly Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Count per year · ${_metricValueLabel()}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          MockupCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: sortedYears
                  .map(
                    (entry) => YearBreakdownRow(
                      year: entry.key,
                      count: entry.value,
                      ratio: entry.value / maxCount,
                      valueLabel: _metricValueLabel(),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => YearDetailScreen(
                            year: entry.key,
                            provider: provider,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
