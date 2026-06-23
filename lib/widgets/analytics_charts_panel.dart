import 'package:flutter/material.dart';

import '../models/openalex_impact_profile.dart';
import '../models/openalex_ranked_entity.dart';
import '../providers/publication_provider.dart';
import '../screens/author_detail_screen.dart';
import '../screens/domain_detail_screen.dart';
import '../screens/institution_detail_screen.dart';
import '../screens/journal_detail_screen.dart';
import '../screens/year_detail_screen.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';
import 'expandable_ranked_chart.dart';
import 'journal_bar_chart.dart';
import 'keyword_bar_chart.dart';
import 'open_access_donut_chart.dart';
import 'trend_chart.dart';
import 'productivity_scatter_chart.dart';
import 'year_volume_bar_chart.dart';

/// Dữ liệu chung cho biểu đồ Overview và Explore.
class AnalyticsChartsData {
  final Map<int, int> volumeTrend;
  final Map<int, int>? citationTrend;
  final bool isMonthly;
  final String rangeLabel;
  final int openAccessCount;
  final int closedAccessCount;
  final List<OpenAlexRankedEntity> topics;
  final List<OpenAlexRankedEntity> institutions;
  final List<OpenAlexRankedEntity> worksByType;
  final List<OpenAlexRankedEntity> journals;
  final List<OpenAlexRankedEntity> authors;
  final List<OpenAlexRankedEntity> authorsByCitations;
  final List<OpenAlexRankedEntity> institutionsByCitations;
  final List<OpenAlexRankedEntity> countries;
  final List<OpenAlexRankedEntity> authorsByHIndex;
  final List<OpenAlexImpactProfile> authorImpactProfiles;
  const AnalyticsChartsData({
    required this.volumeTrend,
    required this.rangeLabel,
    this.citationTrend,
    this.isMonthly = false,
    this.openAccessCount = 0,
    this.closedAccessCount = 0,
    this.topics = const [],
    this.institutions = const [],
    this.worksByType = const [],
    this.journals = const [],
    this.authors = const [],
    this.authorsByCitations = const [],
    this.institutionsByCitations = const [],
    this.countries = const [],
    this.authorsByHIndex = const [],
    this.authorImpactProfiles = const [],
  });
}

/// Bộ biểu đồ analytics — dùng chung Overview và Explore.
class AnalyticsChartsPanel extends StatelessWidget {
  final AnalyticsChartsData data;
  final String sectionTitle;
  final bool isLoading;
  final PublicationProvider? provider;

  const AnalyticsChartsPanel({
    super.key,
    required this.data,
    this.sectionTitle = 'Publication Analytics',
    this.isLoading = false,
    this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && data.volumeTrend.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final citationTrend = data.citationTrend;
    final rangeLabel = data.rangeLabel;
    final isMonthly = data.isMonthly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(sectionTitle),
        const SizedBox(height: 4),
        Text(
          'Khoảng: $rangeLabel · OpenAlex',
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        _chartCard(
          title: isMonthly ? 'Month' : 'Year',
          subtitle: isMonthly
              ? 'Publication volume by month · $rangeLabel'
              : 'Publication volume by year · $rangeLabel',
          child: YearVolumeBarChart(
            yearlyData: data.volumeTrend,
            isMonthly: isMonthly,
            onYearTap: provider == null || isMonthly
                ? null
                : (year) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => YearDetailScreen(
                          year: year,
                          provider: provider!,
                        ),
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 14),
        _chartCard(
          title: 'Publication Trend',
          subtitle: isMonthly
              ? 'Monthly volume · $rangeLabel'
              : 'Volume with citation overlay · $rangeLabel',
          child: TrendChart(
            yearlyData: data.volumeTrend,
            overlayYearlyData:
                citationTrend == null || citationTrend.isEmpty
                    ? null
                    : citationTrend,
            isMonthly: isMonthly,
          ),
        ),
        const SizedBox(height: 14),
        if (data.openAccessCount + data.closedAccessCount > 0)
          _chartCard(
            title: 'Open Access',
            subtitle: 'Share of works in scope',
            child: OpenAccessDonutChart(
              openAccessCount: data.openAccessCount,
              closedCount: data.closedAccessCount,
            ),
          ),
        if (data.openAccessCount + data.closedAccessCount > 0)
          const SizedBox(height: 14),
        if (data.topics.isNotEmpty)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'Topic',
              subtitle: 'Top research topics',
              items: _toEntries(data.topics),
              chartBuilder: (items) => KeywordBarChart(
                title: '',
                showFooter: false,
                items: items,
                onItemTap: (name) => _openTopicByName(context, name),
              ),
            ),
          ),
        if (data.topics.isNotEmpty) const SizedBox(height: 14),
        if (data.institutions.isNotEmpty)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'Institution',
              subtitle: 'Top publishing institutions',
              items: _toEntries(data.institutions),
              chartBuilder: (items) => KeywordBarChart(
                title: '',
                showFooter: false,
                items: items,
                onItemTap: provider == null
                    ? null
                    : (name) => _openInstitutionByName(context, name),
              ),
            ),
          ),
        if (data.institutions.isNotEmpty) const SizedBox(height: 14),
        if (data.worksByType.isNotEmpty)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'Type',
              subtitle: 'Works by document type',
              items: data.worksByType
                  .map((e) => MapEntry(_formatTypeName(e.name), e.count))
                  .toList(),
              chartBuilder: (items) => KeywordBarChart(
                title: '',
                showFooter: false,
                items: items,
              ),
            ),
          ),
        if (data.worksByType.isNotEmpty) const SizedBox(height: 14),
        if (data.journals.isNotEmpty)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'Publication Sources',
              subtitle: 'Top journals and venues',
              items: _toEntries(data.journals),
              chartBuilder: (items) => JournalBarChart(
                showHeader: false,
                journals: items,
                onJournalTap: provider == null
                    ? null
                    : (name) => _openJournalByName(context, name),
              ),
            ),
          ),
        if (data.journals.isNotEmpty) const SizedBox(height: 14),
        if (data.authors.isNotEmpty)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'Research Leaders',
              subtitle: 'Authors with most publications',
              items: _toEntries(data.authors),
              chartBuilder: (items) => KeywordBarChart(
                title: '',
                showFooter: false,
                items: items,
                onItemTap: provider == null
                    ? null
                    : (name) => _openAuthorByName(context, name),
              ),
            ),
          ),
        if (data.authors.isNotEmpty) const SizedBox(height: 14),
        if (data.authorsByCitations.length >= 2)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'Citation Leaders',
              subtitle: data.topics.isNotEmpty
                  ? 'Authors in matched topics · career citations'
                  : 'Authors ranked by citations in search results',
              items: _toEntries(data.authorsByCitations),
              chartBuilder: (items) => KeywordBarChart(
                title: '',
                showFooter: false,
                items: items,
                valueLabel: 'citations',
                onItemTap: provider == null
                    ? null
                    : (name) => _openAuthorByName(
                          context,
                          name,
                          data.authorsByCitations,
                        ),
              ),
            ),
          ),
        if (data.authorsByCitations.length >= 2) const SizedBox(height: 14),
        if (data.institutionsByCitations.length >= 2)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'Institution Impact',
              subtitle: 'Institutions ranked by total citations',
              items: _toEntries(data.institutionsByCitations),
              chartBuilder: (items) => KeywordBarChart(
                title: '',
                showFooter: false,
                items: items,
                valueLabel: 'citations',
                onItemTap: provider == null
                    ? null
                    : (name) => _openInstitutionByName(
                          context,
                          name,
                          data.institutionsByCitations,
                        ),
              ),
            ),
          ),
        if (data.institutionsByCitations.length >= 2) const SizedBox(height: 14),
        if (data.countries.isNotEmpty)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'Countries',
              subtitle: 'Works by author country in scope',
              items: _toEntries(data.countries),
              chartBuilder: (items) => KeywordBarChart(
                title: '',
                showFooter: false,
                items: items,
              ),
            ),
          ),
        if (data.countries.isNotEmpty) const SizedBox(height: 14),
        if (data.authorsByHIndex.length >= 2)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'H-Index Leaders',
              subtitle: data.topics.isNotEmpty
                  ? 'Career h-index · authors in matched topics'
                  : 'Career h-index from OpenAlex summary_stats',
              items: _toEntries(data.authorsByHIndex),
              chartBuilder: (items) => KeywordBarChart(
                title: '',
                showFooter: false,
                items: items,
                valueLabel: 'h-index',
                onItemTap: provider == null
                    ? null
                    : (name) => _openAuthorByName(
                          context,
                          name,
                          data.authorsByHIndex,
                        ),
              ),
            ),
          ),
        if (data.authorsByHIndex.length >= 2) const SizedBox(height: 14),
        if (data.authorImpactProfiles.length >= 3)
          _chartCard(
            title: 'Productivity vs Impact',
            subtitle: 'Works count vs total citations · tap a point',
            child: ProductivityScatterChart(
              profiles: data.authorImpactProfiles,
              onPointTap: provider == null
                  ? null
                  : (profile) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthorDetailScreen(
                            author: OpenAlexRankedEntity(
                              id: profile.id,
                              name: profile.name,
                              count: profile.worksCount,
                            ),
                            provider: provider!,
                          ),
                        ),
                      ),
            ),
          ),
        if (data.authorImpactProfiles.length >= 3)
          const SizedBox(height: 14),
        if (data.topics.length >= 2)
          MockupCard(
            child: ExpandableRankedChart(
              title: 'Research Domains',
              subtitle: 'Distribution among top fields',
              items: _toEntries(data.topics),
              chartBuilder: (items) => DomainDonutChart(
                domains: _domainsForEntries(items),
                onDomainTap: provider == null
                    ? null
                    : (domain) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DomainDetailScreen(domain: domain),
                          ),
                        ),
              ),
            ),
          ),
      ],
    );
  }

  void _openAuthorByName(
    BuildContext context,
    String name, [
    List<OpenAlexRankedEntity>? source,
  ]) {
    final author = _entityByName(source ?? data.authors, name);
    if (author == null || provider == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthorDetailScreen(
          author: author,
          provider: provider!,
        ),
      ),
    );
  }

  void _openJournalByName(BuildContext context, String name) {
    final journal = _entityByName(data.journals, name);
    if (journal == null || provider == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalDetailScreen(
          journal: journal,
          provider: provider!,
        ),
      ),
    );
  }

  void _openInstitutionByName(
    BuildContext context,
    String name, [
    List<OpenAlexRankedEntity>? source,
  ]) {
    final institution = _entityByName(source ?? data.institutions, name);
    if (institution == null || provider == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InstitutionDetailScreen(
          institution: institution,
          provider: provider!,
        ),
      ),
    );
  }

  OpenAlexRankedEntity? _entityByName(
    List<OpenAlexRankedEntity> items,
    String name,
  ) {
    for (final item in items) {
      if (item.name == name) return item;
    }
    return null;
  }

  void _openTopicByName(BuildContext context, String name) {
    OpenAlexRankedEntity? domain;
    for (final item in data.topics) {
      if (item.name == name) {
        domain = item;
        break;
      }
    }
    if (domain == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DomainDetailScreen(domain: domain!)),
    );
  }

  List<OpenAlexRankedEntity> _domainsForEntries(
    List<MapEntry<String, int>> items,
  ) {
    final names = items.map((entry) => entry.key).toSet();
    return data.topics.where((topic) => names.contains(topic.name)).toList();
  }

  List<MapEntry<String, int>> _toEntries(List<OpenAlexRankedEntity> entities) {
    return entities.map((e) => MapEntry(e.name, e.count)).toList();
  }

  String _formatTypeName(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return MockupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
