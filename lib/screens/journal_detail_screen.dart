// =============================================================================
// journal_detail_screen.dart — CHI TIẾT JOURNAL / NGUỒN XUẤT BẢN
// =============================================================================
// Filter primary_location.source.id — trend, top authors, papers paginated.
// =============================================================================

import 'package:flutter/material.dart';

import '../models/openalex_ranked_entity.dart';
import '../models/openalex_works_result.dart';
import '../models/publication.dart';
import '../models/research_insight.dart';
import '../viewmodels/publication_viewmodel.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../utils/research_insights.dart';
import '../widgets/app_logo.dart';
import '../widgets/entity_detail_sections.dart';
import '../widgets/ranked_list_widgets.dart';
import 'author_detail_screen.dart';
import '../services/analytics_service.dart';

/// Màn chi tiết **journal/source** — filter `primary_location.source.id`.
class JournalDetailScreen extends StatefulWidget {
  final OpenAlexRankedEntity journal;
  final PublicationViewModel provider;

  const JournalDetailScreen({
    super.key,
    required this.journal,
    required this.provider,
  });

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  List<Publication> _papers = [];
  List<OpenAlexRankedEntity> _authors = [];
  Map<int, int> _trend = {};
  TrendInsight? _insight;
  int _totalCount = 0;
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logViewJournal(
        widget.journal.name,
      );
    _loadInitial();
  }

  /// Papers trang 1 + trend + top authors (song song).
  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _papers = [];
      _page = 0;
    });

    try {
      final results = await Future.wait([
        widget.provider.loadWorksByJournalPage(widget.journal, 1),
        widget.provider.loadJournalTrend(widget.journal),
        widget.provider.loadJournalTopAuthors(widget.journal),
      ]);

      if (!mounted) return;

      final papersResult = results[0] as OpenAlexWorksResult;
      final trend = results[1] as Map<int, int>;

      setState(() {
        _papers = papersResult.publications;
        _totalCount = papersResult.totalOnOpenAlex;
        _page = 1;
        _hasMore = papersResult.hasMore(_papers.length);
        _trend = trend;
        _authors = results[2] as List<OpenAlexRankedEntity>;
        _insight = ResearchInsights.analyzeTrend(
          volumeByYear: trend,
          topicLabel: widget.journal.name,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Phân trang thêm 20 bài.
  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;

    setState(() => _loadingMore = true);

    try {
      final result = await widget.provider.loadWorksByJournalPage(
        widget.journal,
        _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _papers = [..._papers, ...result.publications];
        _page += 1;
        _hasMore = result.hasMore(_papers.length);
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingMore = false;
      });
    }
  }

  /// Avg citations trên các bài đã load.
  double get _avgCitations {
    if (_papers.isEmpty) return 0;
    return _papers.fold<int>(0, (sum, p) => sum + p.citations) / _papers.length;
  }

<<<<<<< HEAD
  Widget _buildLoadedBody(int totalCount, TrendInsight? insight) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.journal.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'OpenAlex journal / source',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        EntityStatsCard(
          totalCount: totalCount,
          avgCitations: _avgCitations,
          loadedCount: _papers.length,
        ),
        if (insight != null) EntityGrowthInsightCard(insight: insight),
        EntityTrendSection(
          title: 'Publication Trend',
          subtitle: 'Works in this journal · OpenAlex',
          trend: _trend,
          emptyMessage: 'No trend data for this journal.',
        ),
        EntityPapersSection(
          title: 'Top Papers',
          subtitle: 'Most cited in this journal',
          papers: _papers,
          totalCount: totalCount,
          isLoadingMore: _loadingMore,
          hasMore: _hasMore,
          onLoadMore: _loadMore,
          emptyMessage: 'No papers found on OpenAlex.',
        ),
        const SizedBox(height: 24),
        const ScreenSectionHeader(
          title: 'Top Authors',
          subtitle: 'Most publications in this journal',
        ),
        const SizedBox(height: 8),
        if (_authors.isEmpty)
          const Text(
            'No author data for this journal.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          MockupCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: _authors.asMap().entries.map((entry) {
                final author = entry.value;
                return RankedMetricTile(
                  rank: entry.key + 1,
                  title: author.name,
                  metricValue: formatOpenAlexCount(author.count),
                  metricLabel: 'publications',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthorDetailScreen(
                        author: author,
                        provider: widget.provider,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(int totalCount, TrendInsight? insight) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _papers.isEmpty) {
      return EntityDetailErrorView(message: _error!, onRetry: _loadInitial);
    }
    return _buildLoadedBody(totalCount, insight);
=======
  int get _totalCitations {
    return _papers.fold<int>(0, (sum, p) => sum + p.citations);
>>>>>>> feature/lab3
  }

  @override
  Widget build(BuildContext context) {
    final totalCount =
        _totalCount > 0 ? _totalCount : widget.journal.count;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.journal.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
<<<<<<< HEAD
      body: _buildBody(totalCount, _insight),
=======
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null && _papers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _loadInitial,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      widget.journal.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'OpenAlex journal / source',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    MockupCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCol(
                              label: 'Publications',
                              value: formatOpenAlexCount(totalCount),
                            ),
                          ),
                          Expanded(
                            child: _StatCol(
                              label: 'Total Citations',
                              value: formatOpenAlexCount(_totalCitations),
                              hint: 'loaded papers',
                            ),
                          ),
                          Expanded(
                            child: _StatCol(
                              label: 'Avg Citations',
                              value: _avgCitations.toStringAsFixed(0),
                              hint: 'per paper',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (insight != null) ...[
                      const SizedBox(height: 16),
                      MockupCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ResearchInsights.formatGrowth(
                                      insight.periodGrowthPercent,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Text(
                                    'Publication growth',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            MomentumBadge(level: insight.momentum),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const ScreenSectionHeader(
                      title: 'Publication Trend',
                      subtitle: 'Works in this journal · OpenAlex',
                    ),
                    const SizedBox(height: 12),
                    MockupCard(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                      child: _trend.isEmpty
                          ? const Text(
                              'No trend data for this journal.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            )
                          : TrendChart(yearlyData: _trend),
                    ),
                    const SizedBox(height: 24),
                    const ScreenSectionHeader(
                      title: 'Top Papers',
                      subtitle: 'Most cited in this journal',
                    ),
                    const SizedBox(height: 8),
                    if (_papers.isEmpty)
                      const Text('No papers found on OpenAlex.')
                    else ...[
                      ..._papers.map(
                        (paper) => PublicationCard(publication: paper),
                      ),
                      LoadMoreFooter(
                        loadedCount: _papers.length,
                        totalCount: totalCount,
                        isLoading: _loadingMore,
                        hasMore: _hasMore,
                        onLoadMore: _loadMore,
                      ),
                    ],
                    const SizedBox(height: 24),
                    const ScreenSectionHeader(
                      title: 'Top Authors',
                      subtitle: 'Most publications in this journal',
                    ),
                    const SizedBox(height: 8),
                    if (_authors.isEmpty)
                      const Text(
                        'No author data for this journal.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      MockupCard(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                          children: _authors.asMap().entries.map((entry) {
                            final author = entry.value;
                            return RankedMetricTile(
                              rank: entry.key + 1,
                              title: author.name,
                              metricValue: formatOpenAlexCount(author.count),
                              metricLabel: 'publications',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AuthorDetailScreen(
                                    author: author,
                                    provider: widget.provider,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;

  const _StatCol({
    required this.label,
    required this.value,
    this.hint,
  });

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
            fontSize: 15,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 9,
            ),
          ),
        ],
      ],
>>>>>>> feature/lab3
    );
  }
}
