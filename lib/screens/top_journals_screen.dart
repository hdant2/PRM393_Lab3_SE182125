import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/publication.dart';
import '../providers/publication_provider.dart';
import 'journal_detail_screen.dart';

import '../providers/publication_provider.dart';
/// Màn hình hiển thị các tạp chí có nhiều bài báo nhất
class TopJournalsScreen extends StatelessWidget {
  const TopJournalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    final topJournals = _getTopJournals(
      provider.publications,
    );

    final topic =
      provider.currentTopic;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Research Journals'),
      ),
      body: topJournals.isEmpty
          ? const Center(
              child: Text('Please search a topic first.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: const Icon(
                        Icons.topic,
                        color: Colors.green,
                      ),
                      title: Text(
                        'Topic: $topic',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${topJournals.length} journals displayed',
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: topJournals.length,
                    itemBuilder: (context, index) {
                      final journal = topJournals[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            journal.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Text(
                            '${journal.value}\nPapers',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            final journalPapers = provider.publications
                                .where(
                                  (publication) =>
                                      publication.journal == journal.key,
                                )
                                .toList();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JournalDetailScreen(
                                  journalName: journal.key,
                                  publications: journalPapers,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Đếm số bài báo theo từng journal
  List<MapEntry<String, int>> _getTopJournals(
    List<Publication> publications,
  ) {
    final Map<String, int> journalCount = {};

    for (final publication in publications) {
      final journal = publication.journal;

      if (journal == 'Unknown Journal') {
        continue;
      }

      journalCount[journal] =
          (journalCount[journal] ?? 0) + 1;
    }

    final sortedJournals =
        journalCount.entries.toList()
          ..sort(
            (a, b) => b.value.compareTo(a.value),
          );

    return sortedJournals.take(10).toList();
  }
}