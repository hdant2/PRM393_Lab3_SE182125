// =============================================================================
// author_detail_screen.dart — CHI TIẾT TÁC GIẢ
// =============================================================================
// API scoped theo authorships.author.id (+ search topic nếu đang Explore).
// Hiển thị: trend chart, top journals, danh sách bài paginated 20/trang.
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
import 'journal_detail_screen.dart';
<<<<<<< HEAD

/// Màn chi tiết **tác giả** — filter `authorships.author.id`.
/// [provider] truyền vào để giữ scope global/topic khi gọi API.
=======
import '../services/analytics_service.dart';
>>>>>>> feature/lab3
class AuthorDetailScreen extends StatefulWidget {
  final OpenAlexRankedEntity author;
  final PublicationViewModel provider;

  const AuthorDetailScreen({
    super.key,
    required this.author,
    required this.provider,
  });

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  /// Dữ liệu scoped theo author id (+ search topic nếu có)
  List<Publication> _papers = [];
  List<OpenAlexRankedEntity> _journals = [];
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
    AnalyticsService.logViewAuthor(
        authorName: widget.author.name,
      );
    _loadInitial();
  }

  /// Load trang 1 papers + trend + top journals (Future.wait song song).
  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _papers = [];
      _page = 0;
    });

    try {
      final results = await Future.wait([
        widget.provider.loadWorksByAuthorPage(widget.author, 1),
        widget.provider.loadAuthorTrend(widget.author),
        widget.provider.loadAuthorTopJournals(widget.author),
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
        _journals = results[2] as List<OpenAlexRankedEntity>;
        _insight = ResearchInsights.analyzeTrend(
          volumeByYear: trend,
          topicLabel: widget.author.name,
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

  /// Load thêm 20 bài — append vào _papers.
  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;

    setState(() => _loadingMore = true);

    try {
      final result = await widget.provider.loadWorksByAuthorPage(
        widget.author,
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

  /// Citations trung bình của các bài đã load (ước lượng trên màn hình).
  double get _avgCitations {
    if (_papers.isEmpty) return 0;
    return _papers.fold<int>(0, (sum, p) => sum + p.citations) / _papers.length;
  }

  Widget _buildLoadedBody(int totalCount, TrendInsight? insight) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        EntityStatsCard(
          totalCount: totalCount,
          avgCitations: _avgCitations,
          loadedCount: _papers.length,
        ),
        if (insight != null) EntityGrowthInsightCard(insight: insight),
        EntityTrendSection(
          title: 'Publication Trend',
          subtitle: 'Works by this author · OpenAlex',
          trend: _trend,
          emptyMessage: 'No trend data for this author.',
        ),
        EntityPapersSection(
          title: 'Top Papers',
          subtitle: 'Most cited works by this author',
          papers: _papers,
          totalCount: totalCount,
          isLoadingMore: _loadingMore,
          hasMore: _hasMore,
          onLoadMore: _loadMore,
          emptyMessage: 'No papers found on OpenAlex.',
        ),
        const SizedBox(height: 24),
        const ScreenSectionHeader(
          title: 'Top Journals',
          subtitle: 'Where this author publishes most',
        ),
        const SizedBox(height: 8),
        if (_journals.isEmpty)
          const Text(
            'No journal data for this author.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          MockupCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: _journals.asMap().entries.map((entry) {
                final journal = entry.value;
                return RankedMetricTile(
                  rank: entry.key + 1,
                  title: journal.name,
                  metricValue: formatOpenAlexCount(journal.count),
                  metricLabel: 'publications',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalDetailScreen(
                        journal: journal,
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _papers.isEmpty) {
      return EntityDetailErrorView(message: _error!, onRetry: _loadInitial);
    }
    return _buildLoadedBody(totalCount, insight);
  }

  @override
  Widget build(BuildContext context) {
    final totalCount =
        _totalCount > 0 ? _totalCount : widget.author.count;

    return Scaffold(
      appBar: AppBar(title: Text(widget.author.name)),
      body: _buildBody(totalCount, _insight),
    );
  }
}
