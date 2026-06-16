import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import '../widgets/trend_chart.dart';
import '../widgets/ranked_list_widgets.dart';
import 'author_detail_screen.dart';
import 'journal_detail_screen.dart';

class DomainDetailScreen extends StatefulWidget {
  final OpenAlexRankedEntity domain;

  const DomainDetailScreen({super.key, required this.domain});

  @override
  State<DomainDetailScreen> createState() => _DomainDetailScreenState();
}

class _DomainDetailScreenState extends State<DomainDetailScreen> {
  Map<int, int> _trend = {};
  List<OpenAlexRankedEntity> _authors = [];
  List<OpenAlexRankedEntity> _journals = [];
  List<Publication> _papers = [];
  int _papersTotal = 0;
  int _papersPage = 0;
  bool _papersHasMore = false;
  TrendInsight? _insight;
  bool _loading = true;
  bool _loadingMorePapers = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final provider = context.read<PublicationProvider>();
      final results = await Future.wait([
        provider.loadConceptTrend(widget.domain),
        provider.loadConceptTopAuthors(widget.domain),
        provider.loadConceptTopJournals(widget.domain),
        provider.loadConceptWorksPage(widget.domain, 1),
      ]);

      if (!mounted) return;

      final trend = results[0] as Map<int, int>;
      final papersResult = results[3] as OpenAlexWorksResult;

      setState(() {
        _trend = trend;
        _authors = results[1] as List<OpenAlexRankedEntity>;
        _journals = results[2] as List<OpenAlexRankedEntity>;
        _papers = papersResult.publications;
        _papersTotal = papersResult.totalOnOpenAlex;
        _papersPage = 1;
        _papersHasMore = papersResult.hasMore(_papers.length);
        _insight = ResearchInsights.analyzeTrend(
          volumeByYear: trend,
          topicLabel: widget.domain.name,
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

  Future<void> _loadMorePapers() async {
    if (!_papersHasMore || _loadingMorePapers) return;

    setState(() => _loadingMorePapers = true);

    try {
      final provider = context.read<PublicationProvider>();
      final result = await provider.loadConceptWorksPage(
        widget.domain,
        _papersPage + 1,
      );
      if (!mounted) return;
      setState(() {
        _papers = [..._papers, ...result.publications];
        _papersPage += 1;
        _papersHasMore = result.hasMore(_papers.length);
        _loadingMorePapers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingMorePapers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final insight = _insight;
    final totalCount =
        _papersTotal > 0 ? _papersTotal : widget.domain.count;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.domain.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null && insight == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    MockupCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatOpenAlexCount(totalCount),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Publications in this domain',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          if (insight != null) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ResearchInsights.formatGrowth(
                                          insight.periodGrowthPercent,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        'Domain growth',
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
                            const SizedBox(height: 6),
                            Text(
                              insight.headline,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const ScreenSectionHeader(
                      title: 'Publication Trend',
                      subtitle: 'Works tagged with this OpenAlex concept',
                    ),
                    const SizedBox(height: 12),
                    MockupCard(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                      child: _trend.isEmpty
                          ? const Text(
                              'No trend data for this domain.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            )
                          : TrendChart(yearlyData: _trend),
                    ),
                    const SizedBox(height: 24),
                    const ScreenSectionHeader(
                      title: 'Top Papers',
                      subtitle: 'Most cited in this domain',
                    ),
                    const SizedBox(height: 8),
                    if (_papers.isEmpty)
                      const Text(
                        'No papers loaded for this domain.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else ...[
                      ..._papers.map(
                        (paper) => PublicationCard(publication: paper),
                      ),
                      LoadMoreFooter(
                        loadedCount: _papers.length,
                        totalCount: totalCount,
                        isLoading: _loadingMorePapers,
                        hasMore: _papersHasMore,
                        onLoadMore: _loadMorePapers,
                      ),
                    ],
                    const SizedBox(height: 24),
                    const ScreenSectionHeader(
                      title: 'Top Authors',
                      subtitle: 'Most publications in this domain',
                    ),
                    const SizedBox(height: 8),
                    if (_authors.isEmpty)
                      const Text(
                        'No author data for this domain.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      MockupCard(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                          children: _authors
                              .map(
                                (author) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    author.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${formatOpenAlexCount(author.count)} '
                                    'publications',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 16,
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
                    const SizedBox(height: 24),
                    const ScreenSectionHeader(
                      title: 'Top Journals',
                      subtitle: 'Where this domain publishes most',
                    ),
                    const SizedBox(height: 8),
                    if (_journals.isEmpty)
                      const Text(
                        'No journal data for this domain.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      MockupCard(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                          children: _journals
                              .map(
                                (journal) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    journal.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${formatOpenAlexCount(journal.count)} '
                                    'publications',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JournalDetailScreen(
                                        journal: journal,
                                        provider: provider,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class DomainDonutChart extends StatelessWidget {
  final List<OpenAlexRankedEntity> domains;

  const DomainDonutChart({super.key, required this.domains});

  static const _chartColors = [
    AppColors.textPrimary,
    AppColors.textSecondary,
    AppColors.textTertiary,
    Color(0xFFCCCCCC),
    Color(0xFFDDDDDD),
    Color(0xFFEEEEEE),
    Color(0xFFB0B0B0),
    Color(0xFF909090),
  ];

  @override
  Widget build(BuildContext context) {
    if (domains.isEmpty) return const SizedBox.shrink();

    final total = domains.fold<int>(0, (sum, d) => sum + d.count);
    final legendItems = domains.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      for (var i = 0; i < domains.length; i++)
                        PieChartSectionData(
                          value: domains[i].count.toDouble(),
                          color: _chartColors[i % _chartColors.length],
                          radius: 28,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < legendItems.length; i++)
                      _LegendRow(
                        color: _chartColors[i % _chartColors.length],
                        name: legendItems[i].name,
                        count: legendItems[i].count,
                        percent: total > 0
                            ? legendItems[i].count / total * 100
                            : 0,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share among top ${domains.length} domains shown below',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String name;
  final int count;
  final double percent;

  const _LegendRow({
    required this.color,
    required this.name,
    required this.count,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Text(
            '${formatOpenAlexCount(count)} · ${percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
