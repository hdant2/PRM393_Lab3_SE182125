import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/openalex_ranked_entity.dart';
import '../providers/publication_provider.dart';
import '../utils/count_format.dart';
import 'journal_detail_screen.dart';

/// 4.5 Top Research Journals
class TopJournalsScreen extends StatelessWidget {
  const TopJournalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final topJournals = provider.rankedJournals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Research Journals (OpenAlex)'),
      ),
      body: topJournals.isEmpty
          ? const Center(child: Text('No journal rankings from OpenAlex yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topJournals.length,
              itemBuilder: (context, index) {
                final journal = topJournals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(
                      journal.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${formatOpenAlexCount(journal.count)}\nworks',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _openJournal(context, provider, journal),
                  ),
                );
              },
            ),
    );
  }

  void _openJournal(
    BuildContext context,
    PublicationProvider provider,
    OpenAlexRankedEntity journal,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalDetailScreen(
          journal: journal,
          provider: provider,
        ),
      ),
    );
  }
}
