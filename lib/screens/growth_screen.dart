// =============================================================================
// growth_screen.dart — RESEARCH GROWTH (diagram trend mở rộng)
// =============================================================================
// Chart + CAGR + growth bars theo domain. Mở từ Overview tile.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/openalex_ranked_entity.dart';
import '../models/research_insight.dart';
import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../utils/research_insights.dart';
import '../widgets/app_logo.dart';
import '../widgets/insight_widgets.dart';
import '../widgets/trend_chart.dart';
import 'domain_detail_screen.dart';

enum GrowthRange { all, fiveYear, tenYear }

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  GrowthRange _range = GrowthRange.all;

  Map<int, int> _filterTrend(Map<int, int> source) {
    if (source.isEmpty) return source;
    final currentYear = DateTime.now().year;
    final startYear = switch (_range) {
      GrowthRange.all => source.keys.reduce((a, b) => a < b ? a : b),
      GrowthRange.fiveYear => currentYear - 4,
      GrowthRange.tenYear => currentYear - 9,
    };
    return Map.fromEntries(
      source.entries.where((e) => e.key >= startYear),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final trend = _filterTrend(provider.yearlyTrendFromOpenAlex);
    final insight = ResearchInsights.analyzeTrend(volumeByYear: trend);
    final domains = provider.growingTopicsOpenAlex.isNotEmpty
        ? provider.growingTopicsOpenAlex
        : provider.trendingAreas
            .map(
              (d) => TopicGrowthInsight(
                id: d.id,
                name: d.name,
                growthPercent: 0,
              ),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Research Growth'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<GrowthRange>(
            segments: const [
              ButtonSegment(value: GrowthRange.all, label: Text('All')),
              ButtonSegment(value: GrowthRange.fiveYear, label: Text('5Y')),
              ButtonSegment(value: GrowthRange.tenYear, label: Text('10Y')),
            ],
            selected: {_range},
            onSelectionChanged: (v) => setState(() => _range = v.first),
          ),
          const SizedBox(height: 20),
          const Text(
            'Publication Volume Over Time',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Number of publications per year · OpenAlex',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          MockupCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: trend.isEmpty
                ? const Text('No trend data')
                : TrendChart(yearlyData: trend),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _GrowthStat(
                  label: 'CAGR',
                  value: ResearchInsights.formatGrowth(
                    insight.avgAnnualGrowthPercent,
                  ),
                ),
              ),
              Expanded(
                child: _GrowthStat(
                  label: 'Peak Year',
                  value: '${insight.peakYear}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Growth by Top Domains',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a domain for papers, authors & journals',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          MockupCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: domains.isEmpty
                ? const Text(
                    'Loading domain growth...',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Domain',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Relative growth',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      ...domains.take(5).map((domain) {
                        final width = (domain.growthPercent.abs() / 320)
                            .clamp(0.08, 1.0);
                        final entity = provider.rankedConceptById(domain.id) ??
                            OpenAlexRankedEntity(
                              id: domain.id,
                              name: domain.name,
                              count: 0,
                            );
                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DomainDetailScreen(domain: entity),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    domain.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: width,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.textPrimary,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    GrowthLabel(percent: domain.growthPercent),
                                    const Text(
                                      'growth',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 14,
                                  color: AppColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GrowthStat extends StatelessWidget {
  final String label;
  final String value;

  const _GrowthStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return MockupCard(
      padding: const EdgeInsets.all(14),
      child: Column(
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
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
