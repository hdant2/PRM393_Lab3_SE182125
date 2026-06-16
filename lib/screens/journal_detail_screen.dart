import 'package:flutter/material.dart';

import '../models/openalex_ranked_entity.dart';
import '../models/openalex_works_result.dart';
import '../models/publication.dart';
import '../models/research_insight.dart';
import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../utils/research_insights.dart';
import '../widgets/app_logo.dart';
import '../widgets/insight_widgets.dart';
import '../widgets/load_more_footer.dart';
import '../widgets/publication_card.dart';
import '../widgets/ranked_list_widgets.dart';
import '../widgets/trend_chart.dart';
import 'author_detail_screen.dart';

class JournalDetailScreen extends StatefulWidget {
  final OpenAlexRankedEntity journal;
  final PublicationProvider provider;

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
    _loadInitial();
  }

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

  double get _avgCitations {
    if (_papers.isEmpty) return 0;
    return _papers.fold<int>(0, (sum, p) => sum + p.citations) / _papers.length;
  }

  @override
  Widget build(BuildContext context) {
    final totalCount =
        _totalCount > 0 ? _totalCount : widget.journal.count;
    final insight = _insight;

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
                              label: 'Avg Citations',
                              value: _avgCitations.toStringAsFixed(0),
                              hint: 'loaded papers',
                            ),
                          ),
                          Expanded(
                            child: _StatCol(
                              label: 'Loaded',
                              value: '${_papers.length}',
                              hint: 'on screen',
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
    );
  }
}
