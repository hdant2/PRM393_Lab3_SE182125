import 'package:flutter/material.dart';

import '../providers/publication_provider.dart';
import '../utils/analytics_year.dart';
import '../utils/overview_time_range.dart';
import 'analytics_charts_panel.dart';

/// Biểu đồ dashboard Overview — hiển thị trực tiếp, không cần bấm vào tile.
class OverviewDashboardCharts extends StatelessWidget {
  final PublicationProvider provider;
  final OverviewTimeRange timeRange;

  const OverviewDashboardCharts({
    super.key,
    required this.provider,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    final volumeTrend = timeRange == OverviewTimeRange.thisYear
        ? provider.dashboardMonthlyTrendFromOpenAlex
        : filterYearlyFromAnalyticsStart(
            filterYearlyDataByRange(
              provider.dashboardYearlyTrendFromOpenAlex,
              timeRange,
            ),
          );
    final citationTrend = timeRange == OverviewTimeRange.thisYear
        ? <int, int>{}
        : filterYearlyFromAnalyticsStart(
            filterYearlyDataByRange(
              provider.dashboardCitationsByYearOpenAlex,
              timeRange,
            ),
          );
    final isMonthly = timeRange == OverviewTimeRange.thisYear;
    final rangeLabel = timeRange.coverageLabelWithMonths(
      DateTime.now().year,
      provider.dashboardMonthlyTrendFromOpenAlex,
    );

    return AnalyticsChartsPanel(
      isLoading: provider.isTrendLoading &&
          provider.dashboardYearlyTrendFromOpenAlex.isEmpty,
      provider: provider,
      data: AnalyticsChartsData(
        volumeTrend: volumeTrend,
        citationTrend: citationTrend,
        isMonthly: isMonthly,
        rangeLabel: rangeLabel,
        openAccessCount: provider.dashboardOpenAccessCount,
        closedAccessCount: provider.dashboardClosedAccessCount,
        topics: provider.dashboardTrendingAreas,
        institutions: provider.dashboardTopInstitutions,
        worksByType: provider.dashboardWorksByType,
        journals: provider.dashboardRankedJournals,
        authors: provider.dashboardRankedAuthors,
        authorsByCitations: provider.dashboardTopAuthorsByCitations,
        institutionsByCitations: provider.dashboardTopInstitutionsByCitations,
        countries: provider.dashboardCountries,
        authorsByHIndex: provider.dashboardTopAuthorsByHIndex,
        authorImpactProfiles: provider.dashboardAuthorImpactProfiles,
      ),
    );
  }
}
