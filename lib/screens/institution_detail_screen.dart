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
import '../widgets/entity_detail_sections.dart';
import '../widgets/ranked_list_widgets.dart';
import 'author_detail_screen.dart';

/// Màn chi tiết **institution** — filter `authorships.institutions.id`.
class InstitutionDetailScreen extends StatefulWidget {
  final OpenAlexRankedEntity institution;
  final PublicationProvider provider;

  const InstitutionDetailScreen({
    super.key,
    required this.institution,
    required this.provider,
  });

  @override
  State<InstitutionDetailScreen> createState() =>
      _InstitutionDetailScreenState();
}

class _InstitutionDetailScreenState extends State<InstitutionDetailScreen> {
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
        widget.provider.loadWorksByInstitutionPage(widget.institution, 1),
        widget.provider.loadInstitutionTrend(widget.institution),
        widget.provider.loadInstitutionTopAuthors(widget.institution),
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
          topicLabel: widget.institution.name,
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
      final result = await widget.provider.loadWorksByInstitutionPage(
        widget.institution,
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

  Widget _buildLoadedBody(int totalCount, TrendInsight? insight) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.institution.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'OpenAlex institution',
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
          subtitle: 'Works from this institution · OpenAlex',
          trend: _trend,
          emptyMessage: 'No trend data for this institution.',
        ),
        EntityPapersSection(
          title: 'Top Papers',
          subtitle: 'Most cited from this institution',
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
          subtitle: 'Most publications at this institution',
        ),
        const SizedBox(height: 8),
        if (_authors.isEmpty)
          const Text(
            'No author data for this institution.',
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
  }

  @override
  Widget build(BuildContext context) {
    final totalCount =
        _totalCount > 0 ? _totalCount : widget.institution.count;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.institution.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(totalCount, _insight),
    );
  }
}
