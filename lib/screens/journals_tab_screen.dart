import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/openalex_ranked_entity.dart';
import '../viewmodels/publication_viewmodel.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../widgets/app_logo.dart';
import '../widgets/journal_bar_chart.dart';
import '../widgets/ranked_list_widgets.dart';
import 'journal_detail_screen.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import 'search_screen.dart';

class JournalsTabScreen extends StatelessWidget {
  const JournalsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationViewModel>();
    final maxJournals = RemoteConfigService.maxJournals;
    final journals = provider.rankedJournals.take(maxJournals).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                const Text(
                  'Journals',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search, size: 22),
                  tooltip: 'Search topic',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              'Top journals by publication count',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.refreshCurrentAnalysis(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (provider.isTrendLoading && journals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (journals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Text(
                            'No journal data yet. Search for a topic first.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SearchScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Search topic'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    const ScreenSectionHeader(
                      title: 'Publication Statistics',
                      subtitle: 'Publications per journal · OpenAlex',
                    ),
                    const SizedBox(height: 12),
                    MockupCard(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: JournalBarChart(
                        journals: journals.map((j) => j.entry).toList(),
                        onJournalTap: (name) {
                          final journal = provider.rankedJournalByName(name);
                          if (journal == null) return;
                          AnalyticsService.logViewJournal(journal.name);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JournalDetailScreen(
                                journal: journal,
                                provider: provider,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const ScreenSectionHeader(
                      title: 'Top Journals',
                      subtitle: 'Ranked by publication count',
                    ),
                    const SizedBox(height: 8),
                    MockupCard(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: journals.asMap().entries.map((entry) {
                          return RankedMetricTile(
                            rank: entry.key + 1,
                            title: entry.value.name,
                            metricValue: formatOpenAlexCount(entry.value.count),
                            metricLabel: 'publications',
                            onTap: () {
                              AnalyticsService.logViewJournal(
                                entry.value.name,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JournalDetailScreen(
                                    journal: entry.value,
                                    provider: provider,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const ScreenSectionHeader(
                      title: 'Citation Statistics',
                      subtitle: 'Average citations by journal',
                    ),
                    const SizedBox(height: 10),
                    _CitationStatsCard(journals: journals),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CitationStatsCard extends StatelessWidget {
  final List<OpenAlexRankedEntity> journals;

  const _CitationStatsCard({required this.journals});

  @override
  Widget build(BuildContext context) {
    if (journals.isEmpty) return const SizedBox.shrink();

    final totalPublications = journals.fold<int>(
      0,
      (sum, j) => sum + j.count,
    );

    return MockupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Journals',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${journals.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Publications',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatOpenAlexCount(totalPublications),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
