// Tab Overview — UI gốc mockup + bổ sung thầy (KHÔNG xóa phần cũ)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/openalex_ranked_entity.dart';
import '../models/research_insight.dart';
import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../utils/overview_time_range.dart';
import '../utils/research_insights.dart';
import '../widgets/app_logo.dart';
import '../widgets/error_banner.dart';
import '../widgets/overview_dashboard_charts.dart';
import 'author_detail_screen.dart';
import 'detail_screen.dart';
import 'domain_detail_screen.dart';
import 'journal_detail_screen.dart';
/// Overview / Dashboard — màn chính theo mockup JournalAI
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    return SafeArea(
      child: Column(
        children: [
          const JournalAiAppBar(showRefresh: true, showBell: true),
          _OverviewBody(provider: provider),
        ],
      ),
    );
  }
}

class _OverviewBody extends StatefulWidget {
  final PublicationProvider provider;

  const _OverviewBody({required this.provider});

  @override
  State<_OverviewBody> createState() => _OverviewBodyState();
}

class _OverviewBodyState extends State<_OverviewBody> {
  OverviewTimeRange _timeRange = OverviewTimeRange.thisYear;

  PublicationProvider get provider => widget.provider;

  String _peakPeriodLabel(Map<int, int> volume, LandscapePulse pulse) {
    if (volume.isEmpty) return 'N/A';
    if (_timeRange == OverviewTimeRange.thisYear) {
      final peak = volume.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      return monthShortLabel(peak.key);
    }
    return pulse.peakYear > 0 ? '${pulse.peakYear}' : 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    if (provider.isDashboardLoading && !provider.hasDashboardData) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (provider.errorMessage != null && !provider.hasDashboardData) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorBanner(
            message: provider.errorMessage!,
            onRetry: () => provider.loadDefaultDashboard(),
          ),
        ),
      );
    }

    if (!provider.hasDashboardData) {
      return const Expanded(
        child: Center(child: Text('Loading research data...')),
      );
    }

    final currentYear = DateTime.now().year;
    final monthlyTrend = provider.dashboardMonthlyTrendFromOpenAlex;
    final volumeInRange = _timeRange == OverviewTimeRange.thisYear
        ? monthlyTrend
        : filterYearlyDataByRange(
            provider.dashboardYearlyTrendFromOpenAlex,
            _timeRange,
          );
    final publicationsInRange = volumeInRange.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final rangePulse = ResearchInsights.buildLandscapePulse(
      totalPublications: publicationsInRange,
      volumeByYear: _timeRange == OverviewTimeRange.thisYear
          ? volumeInRange
          : volumeInRange,
      averageCitations: provider.dashboardAverageCitationOpenAlex,
    );
    final coverageText = _timeRange.coverageLabelWithMonths(
      currentYear,
      monthlyTrend,
    );

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => provider.loadDefaultDashboard(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ErrorBanner(
                  message: provider.errorMessage!,
                  onRetry: () => provider.loadDefaultDashboard(),
                ),
              ),
                    const Text(
                      'Global Research Overview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<OverviewTimeRange>(
                      segments: OverviewTimeRange.values
                          .map(
                            (range) => ButtonSegment(
                              value: range,
                              label: Text(range.label),
                            ),
                          )
                          .toList(),
                      selected: {_timeRange},
                      onSelectionChanged: (selection) {
                        setState(() => _timeRange = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    MockupCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatOpenAlexCount(
                                        publicationsInRange > 0
                                            ? publicationsInRange
                                            : provider.dashboardTotalOnOpenAlex,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                      ),
                                    ),
                                    const Text(
                                      'Publications',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Influential works · $coverageText · OpenAlex',
                                      style: const TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GrowthBadge(
                                percent: rangePulse.yoyGrowthPercent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              StatColumn(
                                label: 'Average Citations',
                                value: provider.dashboardAverageCitationOpenAlex
                                    .toStringAsFixed(1),
                                hint: 'top 100 avg',
                              ),
                              StatColumn(
                                label: _timeRange == OverviewTimeRange.thisYear
                                    ? 'Peak Month'
                                    : 'Peak Year',
                                value: _peakPeriodLabel(volumeInRange, rangePulse),
                                hint: _timeRange == OverviewTimeRange.thisYear
                                    ? 'most papers'
                                    : 'most papers',
                              ),
                              StatColumn(
                                label: 'Coverage',
                                value: coverageText,
                                hint: 'selected range',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _KeyResearchInsightsSection(provider: provider),
                    const SizedBox(height: 24),
                    OverviewDashboardCharts(
                      provider: provider,
                      timeRange: _timeRange,
                    ),
                    const SizedBox(height: 20),
                    if (provider.dashboardGrowingTopicsOpenAlex.isNotEmpty) ...[
                      const Text(
                        'Emerging Topics',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Concept growth · tap to explore domain',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      MockupCard(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Column(
                          children: provider.dashboardGrowingTopicsOpenAlex
                              .take(5)
                              .map(
                                (topic) => InkWell(
                                  onTap: () {
                                    final domain = provider.dashboardRankedConceptById(
                                          topic.id,
                                        ) ??
                                        OpenAlexRankedEntity(
                                          id: topic.id,
                                          name: topic.name,
                                          count: 0,
                                        );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DomainDetailScreen(
                                          domain: domain,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        const Text(
                                          '🔥',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                topic.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const Text(
                                                'growth vs early period',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              topic.formattedGrowth,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Text(
                                              'growth',
                                              style: TextStyle(
                                                color: AppColors.textTertiary,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: AppColors.textTertiary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}

class _KeyResearchInsightsSection extends StatelessWidget {
  final PublicationProvider provider;

  const _KeyResearchInsightsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.dashboardRankedJournals.isEmpty &&
        provider.dashboardRankedAuthors.isEmpty &&
        provider.dashboardTopPapersOpenAlex.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        MockupCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Key Research Insights',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dashboard summary · OpenAlex',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              if (provider.dashboardRankedJournals.isNotEmpty)
                _DashboardInsightRow(
                  label: 'Top Journal',
                  value: provider.dashboardRankedJournals.first.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalDetailScreen(
                        journal: provider.dashboardRankedJournals.first,
                        provider: provider,
                      ),
                    ),
                  ),
                ),
              if (provider.dashboardRankedAuthors.isNotEmpty)
                _DashboardInsightRow(
                  label: 'Top Author',
                  value: provider.dashboardRankedAuthors.first.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthorDetailScreen(
                        author: provider.dashboardRankedAuthors.first,
                        provider: provider,
                      ),
                    ),
                  ),
                ),
              if (provider.dashboardTopPapersOpenAlex.isNotEmpty)
                _DashboardInsightRow(
                  label: 'Most Influential Paper',
                  value: provider.dashboardTopPapersOpenAlex.first.title,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(
                        publication: provider.dashboardTopPapersOpenAlex.first,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardInsightRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DashboardInsightRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
