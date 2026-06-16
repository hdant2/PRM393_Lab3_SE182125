// =============================================================================
// journals_analysis_screen.dart — JOURNAL RANKING (#14)
// =============================================================================
// JournalBarChart + ranked list — tab Journals trong Keywords hub.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../utils/count_format.dart';
import '../widgets/app_logo.dart';
import '../widgets/journal_bar_chart.dart';
import '../widgets/ranked_list_widgets.dart';
import 'journal_detail_screen.dart';
import 'top_journals_screen.dart';

class JournalsAnalysisScreen extends StatelessWidget {
  const JournalsAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final journals = provider.rankedJournals;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Publication Sources'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Journals'),
              Tab(text: 'Publishers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const ScreenSectionHeader(
                  title: 'Top Journals by Publications',
                  subtitle: 'Bar length = publication count · OpenAlex',
                ),
                const SizedBox(height: 16),
                MockupCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: JournalBarChart(
                    journals: journals.map((j) => j.entry).toList(),
                    onJournalTap: (name) {
                      final journal = provider.rankedJournalByName(name);
                      if (journal == null) return;
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
                const SizedBox(height: 20),
                const RankedListHeader(metricColumnLabel: 'Publications'),
                ...journals.asMap().entries.map(
                      (entry) => RankedMetricTile(
                        rank: entry.key + 1,
                        title: entry.value.name,
                        metricValue: formatOpenAlexCount(entry.value.count),
                        metricLabel: 'publications',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JournalDetailScreen(
                              journal: entry.value,
                              provider: provider,
                            ),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TopJournalsScreen(),
                    ),
                  ),
                  child: const Text('View All Journals'),
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const ScreenSectionHeader(
                  title: 'Top Publishing Venues',
                  subtitle: 'Grouped by OpenAlex source · publication count',
                ),
                const SizedBox(height: 16),
                const RankedListHeader(metricColumnLabel: 'Publications'),
                ...journals.asMap().entries.map(
                      (entry) => MockupCard(
                        padding: const EdgeInsets.all(14),
                        child: RankedMetricTile(
                          rank: entry.key + 1,
                          title: entry.value.name,
                          metricValue: formatOpenAlexCount(entry.value.count),
                          metricLabel: 'publications',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JournalDetailScreen(
                                journal: entry.value,
                                provider: provider,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
