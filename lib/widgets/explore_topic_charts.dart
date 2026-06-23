import 'package:flutter/material.dart';

import '../providers/publication_provider.dart';
import '../utils/analytics_year.dart';
import '../utils/overview_time_range.dart';
import 'analytics_charts_panel.dart';

/// Biểu đồ đầy đủ cho kết quả tìm kiếm topic trên Explore.
class ExploreTopicCharts extends StatelessWidget {
  final PublicationProvider provider;
  final OverviewTimeRange timeRange;

  const ExploreTopicCharts({
    super.key,
    required this.provider,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final monthlyTrend = provider.monthlyTrendFromOpenAlex;
    final volumeTrend = timeRange == OverviewTimeRange.thisYear
        ? monthlyTrend
        : filterYearlyFromAnalyticsStart(
            filterYearlyDataByRange(
              provider.yearlyTrendFromOpenAlex,
              timeRange,
            ),
          );
    final citationTrend = timeRange == OverviewTimeRange.thisYear
        ? <int, int>{}
        : filterYearlyFromAnalyticsStart(
            filterYearlyDataByRange(
              provider.citationsByYearOpenAlex,
              timeRange,
            ),
          );
    final isMonthly = timeRange == OverviewTimeRange.thisYear;
    final rangeLabel = timeRange.coverageLabelWithMonths(
      currentYear,
      monthlyTrend,
    );

    return AnalyticsChartsPanel(
      sectionTitle: 'Topic Analytics',
      isLoading: provider.isTrendLoading,
      provider: provider,
      data: AnalyticsChartsData(
        volumeTrend: volumeTrend,
        citationTrend: citationTrend,
        isMonthly: isMonthly,
        rangeLabel: rangeLabel,
        openAccessCount: provider.openAccessCountOpenAlex,
        closedAccessCount: provider.closedAccessCountOpenAlex,
        topics: provider.trendingAreas,
        institutions: provider.topInstitutionsOpenAlex,
        worksByType: provider.worksByTypeOpenAlex,
        journals: provider.rankedJournals,
        authors: provider.rankedAuthors,
        authorsByCitations: provider.topAuthorsByCitationsOpenAlex,
        institutionsByCitations: provider.topInstitutionsByCitationsOpenAlex,
        countries: provider.countriesOpenAlex,
        authorsByHIndex: provider.topAuthorsByHIndexOpenAlex,
        authorImpactProfiles: provider.authorImpactProfilesOpenAlex,
      ),
    );
  }
}
