// =============================================================================
// year_detail_screen.dart — CHI TIẾT MỘT NĂM TRÊN BIỂU ĐỒ
// =============================================================================
// Tap cột năm trên TrendScreen → papers năm đó + hot topics (concepts).
// Chip concept tap → DomainDetailScreen.
// =============================================================================

import 'package:flutter/material.dart';

import '../models/openalex_ranked_entity.dart';
import '../models/openalex_works_result.dart';
import '../models/publication.dart';
import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../widgets/app_logo.dart';
import '../widgets/load_more_footer.dart';
import '../widgets/publication_card.dart';
import 'domain_detail_screen.dart';

class YearDetailScreen extends StatefulWidget {
  final int year;
  final PublicationProvider provider;

  const YearDetailScreen({
    super.key,
    required this.year,
    required this.provider,
  });

  @override
  State<YearDetailScreen> createState() => _YearDetailScreenState();
}

class _YearDetailScreenState extends State<YearDetailScreen> {
  List<Publication> _papers = [];
  List<OpenAlexRankedEntity> _hotTopics = [];
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
        widget.provider.loadPublicationsForYearPage(widget.year, 1),
        widget.provider.loadConceptsForYear(widget.year),
      ]);
      if (!mounted) return;

      final papersResult = results[0] as OpenAlexWorksResult;
      setState(() {
        _papers = papersResult.publications;
        _totalCount = papersResult.totalOnOpenAlex;
        _hotTopics = results[1] as List<OpenAlexRankedEntity>;
        _page = 1;
        _hasMore = papersResult.hasMore(_papers.length);
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
      final result = await widget.provider.loadPublicationsForYearPage(
        widget.year,
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

  @override
  Widget build(BuildContext context) {
    final openAlexCount = widget.provider.openAlexCountForYear(widget.year);
    final totalCount = _totalCount > 0 ? _totalCount : openAlexCount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Year ${widget.year}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                MockupCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _YearStat(
                          label: 'Publications',
                          value: formatOpenAlexCount(totalCount),
                        ),
                      ),
                      Expanded(
                        child: _YearStat(
                          label: 'Loaded',
                          value: '${_papers.length}',
                        ),
                      ),
                      Expanded(
                        child: _YearStat(
                          label: 'Top Journal',
                          value: _papers.isEmpty
                              ? 'N/A'
                              : _papers.first.journal.split(' ').first,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  TextButton(onPressed: _loadInitial, child: const Text('Retry')),
                ],
                if (_hotTopics.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Hot topics (OpenAlex)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap a topic to explore papers, authors & journals',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _hotTopics
                        .map(
                          (topic) => ActionChip(
                            label: Text(
                              '${topic.name} (${formatOpenAlexCount(topic.count)} publications)',
                            ),
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(color: AppColors.border),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DomainDetailScreen(
                                  domain: topic,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Top Cited Papers in ${widget.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_papers.isEmpty)
                  const Text(
                    'No papers loaded for this year.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
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
              ],
            ),
    );
  }
}

class _YearStat extends StatelessWidget {
  final String label;
  final String value;

  const _YearStat({required this.label, required this.value});

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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
