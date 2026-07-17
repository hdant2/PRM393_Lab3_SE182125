// =============================================================================
// citation_leaders_screen.dart — TOP PAPERS + AUTHORS THEO CITATIONS
// =============================================================================
// Sort cited_by_count — khác danh sách Explore (relevance).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/publication_viewmodel.dart';
import '../utils/count_format.dart';
import '../widgets/ranked_list_widgets.dart';
import 'author_detail_screen.dart';
import 'detail_screen.dart';
import 'journal_detail_screen.dart';
import 'research_leaders_screen.dart';

class CitationLeadersScreen extends StatelessWidget {
  const CitationLeadersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Citation Leaders'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Papers'),
              Tab(text: 'Authors'),
              Tab(text: 'Journals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PapersTab(),
            _AuthorsTab(),
            _JournalsTab(),
          ],
        ),
      ),
    );
  }
}

class _PapersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // [Merge resolved] Chọn feature/lab3: PublicationViewModel thay vì PublicationProvider
    final papers = context.watch<PublicationViewModel>().dashboardTopPapersOpenAlex;

    if (papers.isEmpty) {
      return const Center(child: Text('No papers from OpenAlex'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const RankedListHeader(metricColumnLabel: 'Citations'),
        ...papers.asMap().entries.map((entry) {
          final paper = entry.value;
          final authors = paper.authors.take(2).join(', ');
          return RankedMetricTile(
            rank: entry.key + 1,
            title: paper.title,
            subtitle: '$authors · ${paper.year} · ${paper.journal}',
            metricValue: formatOpenAlexCount(paper.citations),
            metricLabel: 'citations',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(publication: paper),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AuthorsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // [Merge resolved] Chọn feature/lab3: PublicationViewModel + rankedAuthors
    final provider = context.watch<PublicationViewModel>();
    final authors = provider.rankedAuthors;

    if (authors.isEmpty) {
      return const Center(child: Text('No authors from OpenAlex'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ResearchLeadersScreen(),
              ),
            ),
            icon: const Icon(Icons.leaderboard_outlined, size: 18),
            label: const Text('Research leaders by volume'),
          ),
        ),
        const RankedListHeader(metricColumnLabel: 'Publications'),
        ...authors.asMap().entries.map(
              (entry) => RankedMetricTile(
                rank: entry.key + 1,
                title: entry.value.name,
                metricValue: formatOpenAlexCount(entry.value.count),
                metricLabel: 'publications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AuthorDetailScreen(
                      author: entry.value,
                      provider: provider,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _JournalsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // [Merge resolved] Chọn feature/lab3: PublicationViewModel + rankedJournals
    final provider = context.watch<PublicationViewModel>();
    final journals = provider.rankedJournals;

    if (journals.isEmpty) {
      return const Center(child: Text('No journals from OpenAlex'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const RankedListHeader(metricColumnLabel: 'Publications'),
        ...journals.asMap().entries.map(
              (entry) => RankedMetricTile(
                rank: entry.key + 1,
                title: entry.value.name,
                subtitle: 'OpenAlex source / journal',
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
      ],
    );
  }
}
