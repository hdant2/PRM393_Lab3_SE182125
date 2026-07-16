<<<<<<< HEAD
// =============================================================================
=======
﻿// =============================================================================
>>>>>>> feature/lab3
// search_screen.dart — EXPLORE / SEARCH (màn cũ, mở từ Home)
// =============================================================================
// Search topic → provider.searchPublications → snapshot + load more 20 bài.
// Recent Searches chips khi chưa search. SearchLoadingView khi chờ bài đầu.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/research_insight.dart';
import '../viewmodels/publication_viewmodel.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../utils/overview_time_range.dart';
import '../utils/research_insights.dart';
import '../widgets/app_logo.dart';
import '../widgets/error_banner.dart';
import '../widgets/insight_widgets.dart';
import '../widgets/explore_topic_charts.dart';
import '../widgets/load_more_footer.dart';
import '../widgets/publication_card.dart';
import '../widgets/search_loading_view.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const _quickExplore = [
    'Artificial Intelligence',
    'Cybersecurity',
    'Blockchain',
    'Data Science',
    'Generative AI',
  ];

  @override
  void initState() {
    super.initState();
    final preset = widget.initialQuery?.trim();
    if (preset != null && preset.isNotEmpty) {
      _searchController.text = preset;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
<<<<<<< HEAD
      context.read<PublicationProvider>().loadRecentSearches();
=======
      context.read<PublicationViewModel>().loadRecentSearches();
>>>>>>> feature/lab3
    });
  }

  /// Gọi provider.searchPublications — presetTopic dùng cho chip gợi ý
  Future<void> _search([String? presetTopic]) async {
    if (presetTopic != null) _searchController.text = presetTopic;
    final topic = _searchController.text.trim();
    if (topic.isEmpty) return;

    await context.read<PublicationViewModel>().searchPublications(topic);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget? _buildSearchSuffixIcon(bool showSearchLoading) {
    if (showSearchLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.arrow_forward, size: 20),
      onPressed: () => _search(),
    );
  }

  Widget _buildExpandedContent({
<<<<<<< HEAD
    required PublicationProvider provider,
=======
    required PublicationViewModel provider,
>>>>>>> feature/lab3
    required bool showSearchLoading,
    required bool inTopicScope,
  }) {
    if (showSearchLoading) {
      return SearchLoadingView(query: provider.currentTopic);
    }
    if (inTopicScope) {
      return _ExploreResults(
        provider: provider,
        loadingInsights: provider.isTrendLoading,
      );
    }
    return _ExploreSuggestions(
      onSearch: _search,
      loadingPapers: provider.isSearchLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final provider = context.watch<PublicationProvider>();
=======
    final provider = context.watch<PublicationViewModel>();
>>>>>>> feature/lab3
    final inTopicScope = !provider.isGlobalScope; // đã search hay chưa
    final loadingPapers = provider.isSearchLoading;
    // Chỉ full-screen loading khi chưa có bài nào (search mới)
    final showSearchLoading =
        loadingPapers && provider.publications.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search research topics...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _buildSearchSuffixIcon(showSearchLoading),
              ),
            ),
          ),
          if (provider.errorMessage != null && inTopicScope)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: ErrorBanner(
                message: provider.errorMessage!,
                onRetry: () => _search(),
              ),
            ),
          if (!inTopicScope && provider.recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.recentSearches.map((topic) {
                      return ActionChip(
                        label: Text(topic),
                        onPressed: loadingPapers ? null : () => _search(topic),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          if (inTopicScope)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextButton(
                onPressed: showSearchLoading
                    ? null
                    : () => provider.loadDefaultDashboard(),
                child: const Text('Back to global overview'),
              ),
            ),
          Expanded(
            child: _buildExpandedContent(
              provider: provider,
              showSearchLoading: showSearchLoading,
              inTopicScope: inTopicScope,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ExploreResults extends StatefulWidget {
<<<<<<< HEAD
  final PublicationProvider provider;
=======
  final PublicationViewModel provider;
>>>>>>> feature/lab3
  final bool loadingInsights;

  const _ExploreResults({
    required this.provider,
    required this.loadingInsights,
  });

  @override
  State<_ExploreResults> createState() => _ExploreResultsState();
}

class _ExploreResultsState extends State<_ExploreResults> {
  OverviewTimeRange _timeRange = OverviewTimeRange.fiveYears;

<<<<<<< HEAD
  PublicationProvider get provider => widget.provider;
=======
  PublicationViewModel get provider => widget.provider;
>>>>>>> feature/lab3

  TopicSnapshot? _snapshotForRange() {
    if (!provider.isTopicInsightsReady) return null;
    return ResearchInsights.buildTopicSnapshotForRange(
      topic: provider.currentTopic,
      totalPublications: provider.totalOnOpenAlex,
      yearlyTrend: provider.yearlyTrendFromOpenAlex,
      monthlyTrend: provider.monthlyTrendFromOpenAlex,
      citationsByYear: provider.citationsByYearOpenAlex,
      timeRange: _timeRange,
      topJournal: provider.rankedJournals.isEmpty
          ? null
          : provider.rankedJournals.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snapshotForRange();
    final showInsights = snap != null;
    final currentYear = DateTime.now().year;
    final coverageText = _timeRange.coverageLabelWithMonths(
      currentYear,
      provider.monthlyTrendFromOpenAlex,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (widget.loadingInsights && !showInsights)
          MockupCard(
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.currentTopic,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        'Loading topic insights from OpenAlex…',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (showInsights) ...[
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
                Text(
                  snap.topic,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khoảng: $coverageText · OpenAlex',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SnapshotStat(
                        label: 'Publications',
                        value: formatOpenAlexCount(snap.totalPublications),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SnapshotStat(
                            label: snap.growthLabel,
                            value: ResearchInsights.formatGrowth(
                              snap.growthPercent,
                            ),
                          ),
                          if (snap.growthHint != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              snap.growthHint!,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 9,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SnapshotStat(
                        label: _timeRange == OverviewTimeRange.thisYear
                            ? 'Peak Month'
                            : 'Peak Year',
                        value: _timeRange == OverviewTimeRange.thisYear
                            ? monthShortLabel(snap.peakYear)
                            : '${snap.peakYear}',
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Momentum',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          MomentumBadge(level: snap.momentum),
                        ],
                      ),
                    ),
                  ],
                ),
                if (snap.topJournal != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Top Journal: ${snap.topJournal}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        ExploreTopicCharts(provider: provider, timeRange: _timeRange),
        const SizedBox(height: 20),
        const Text(
          'Publications',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sorted by relevance (OpenAlex default search ranking)',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        if (provider.publications.isEmpty)
          const Text(
            'No publications found for this topic.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else ...[
          ...provider.publications.map(
            (paper) => PublicationCard(publication: paper),
          ),
          LoadMoreFooter(
            loadedCount: provider.publications.length,
            totalCount: provider.totalOnOpenAlex,
            isLoading: provider.isLoadingMorePublications,
            hasMore: provider.searchHasMore,
            onLoadMore: provider.loadMoreSearchPublications,
          ),
        ],
      ],
    );
  }
}

class _ExploreSuggestions extends StatelessWidget {
  final Future<void> Function(String) onSearch;
  final bool loadingPapers;

  const _ExploreSuggestions({
    required this.onSearch,
    required this.loadingPapers,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text(
          'Suggested Topics',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ..._SearchScreenState._quickExplore.map(
          (topic) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: loadingPapers ? null : () => onSearch(topic),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SnapshotStat extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotStat({required this.label, required this.value});

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
