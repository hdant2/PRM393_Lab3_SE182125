import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/publication.dart';
import '../providers/publication_provider.dart';
import 'author_detail_screen.dart';

/// Màn hình hiển thị các tác giả đóng góp nhiều bài báo nhất
class TopAuthorsScreen extends StatelessWidget {
  const TopAuthorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    final topAuthors = _getTopAuthors(
      provider.publications,
    );

    final topic =
      provider.currentTopic;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Contributing Authors'),
      ),
      body: topAuthors.isEmpty
    ? const Center(
        child: Text(
          'Please search a topic first.',
        ),
      )
    : Column(
        children: [

          // =====================================================
          // CURRENT TOPIC
          // =====================================================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.topic,
                  color: Colors.orange,
                ),
                title: Text(
                  'Topic: $topic',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${topAuthors.length} authors displayed',
                ),
              ),
            ),
          ),

          // =====================================================
          // AUTHORS LIST
          // =====================================================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              itemCount: topAuthors.length,
              itemBuilder: (context, index) {
                final author = topAuthors[index];

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        '${index + 1}',
                      ),
                    ),
                    title: Text(
                      author.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      '${author.value}\nPapers',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      final authorPapers =
                          provider.publications
                              .where(
                                (publication) =>
                                    publication.authors.contains(
                                  author.key,
                                ),
                              )
                              .toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AuthorDetailScreen(
                            authorName:
                                author.key,
                            publications:
                                authorPapers,
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

  /// Đếm số bài báo theo từng tác giả
  List<MapEntry<String, int>> _getTopAuthors(
    List<Publication> publications,
  ) {
    final Map<String, int> authorCount = {};

    for (final publication in publications) {
      for (final author in publication.authors) {
        if (author == 'Unknown Author') {
          continue;
        }

        authorCount[author] =
            (authorCount[author] ?? 0) + 1;
      }
    }

    final sortedAuthors = authorCount.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return sortedAuthors.take(10).toList();
  }
}