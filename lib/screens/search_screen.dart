import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/research_insight.dart';
import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../utils/research_insights.dart';
import '../widgets/app_logo.dart';
import '../widgets/error_banner.dart';
import '../widgets/insight_widgets.dart';
import '../widgets/load_more_footer.dart';
import '../widgets/publication_card.dart';
import 'author_detail_screen.dart';
import 'journal_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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

  Future<void> _search([String? presetTopic]) async {
    if (presetTopic != null) _searchController.text = presetTopic;
    final topic = _searchController.text.trim();
    if (topic.isEmpty) return;

    await context.read<PublicationProvider>().searchPublications(topic);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final inTopicScope = !provider.isGlobalScope;
    final snapshot = provider.topicSnapshot;
    final loadingPapers = provider.isSearchLoading;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'Explore',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search research topics...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: loadingPapers
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 20),
                        onPressed: loadingPapers ? null : () => _search(),
                      ),
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
          if (inTopicScope)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextButton(
                onPressed: loadingPapers
                    ? null
                    : () => provider.loadDefaultDashboard(),
                child: const Text('Back to global overview'),
              ),
            ),
          Expanded(
            child: inTopicScope
                ? _ExploreResults(
                    provider: provider,
                    snapshot: snapshot,
                    loadingPapers: loadingPapers,
                    loadingInsights: provider.isTrendLoading,
                  )
                : _ExploreSuggestions(
                    onSearch: _search,
                    loadingPapers: loadingPapers,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExploreResults extends StatelessWidget {
  final PublicationProvider provider;
  final TopicSnapshot? snapshot;
  final bool loadingPapers;
  final bool loadingInsights;

  const _ExploreResults({
    required this.provider,
    required this.snapshot,
    required this.loadingPapers,
    required this.loadingInsights,
  });

  @override
  Widget build(BuildContext context) {
    final snap = snapshot;
    final journals = provider.rankedJournals.take(4).toList();
    final authors = provider.rankedAuthors.take(4).toList();
    final showInsights = provider.isTopicInsightsReady && snap != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (loadingInsights && !showInsights)
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
                      child: _SnapshotStat(
                        label: 'Growth',
                        value: ResearchInsights.formatGrowth(snap.growthPercent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SnapshotStat(
                        label: 'Peak Year',
                        value: '${snap.peakYear}',
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
        if (showInsights && journals.isNotEmpty) ...[
          const Text(
            'Top Journals',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: journals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final journal = journals[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalDetailScreen(
                        journal: journal,
                        provider: provider,
                      ),
                    ),
                  ),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journal.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatOpenAlexCount(journal.count),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const Text(
                          'publications',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (showInsights && authors.isNotEmpty) ...[
          const Text(
            'Top Authors',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8),
          MockupCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: authors
                  .map(
                    (author) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        author.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatOpenAlexCount(author.count),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            'publications',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthorDetailScreen(
                            author: author,
                            provider: provider,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Publications',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (loadingPapers && provider.publications.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (provider.publications.isEmpty)
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
