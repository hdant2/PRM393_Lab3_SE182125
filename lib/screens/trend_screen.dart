import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../utils/research_insights.dart';
import '../widgets/app_logo.dart';
import '../widgets/insight_widgets.dart';
import '../widgets/trend_chart.dart';
import 'year_detail_screen.dart';

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

class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  TrendMetric _metric = TrendMetric.publications;

  Map<int, int> _dataForMetric(PublicationProvider provider) {
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
    final provider = context.watch<PublicationProvider>();

    if (provider.isDashboardLoading && !provider.hasData) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (!provider.hasData) {
      return const SafeArea(
        child: Center(child: Text('Open Overview first')),
      );
    }

    final yearlyData = _dataForMetric(provider);
    final sortedYears = yearlyData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final maxCount = yearlyData.values.isEmpty
        ? 1
        : yearlyData.values.reduce((a, b) => a > b ? a : b);
    final insight = provider.trendInsight;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'Analytics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SegmentedButton<TrendMetric>(
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
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(
                  '${_metric.label} Over Time',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.isGlobalScope
                      ? 'Global research · OpenAlex'
                      : provider.currentTopic,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                if (yearlyData.isEmpty)
                  const Text(
                    'No chart data.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  MockupCard(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    child: TrendChart(yearlyData: yearlyData),
                  ),
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
                      const Text(
                        'period growth · publication volume',
                        style: TextStyle(color: AppColors.textSecondary),
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
            ),
          ),
        ],
      ),
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
