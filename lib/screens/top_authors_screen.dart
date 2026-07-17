// =============================================================================
// top_authors_screen.dart — DANH SÁCH TOP AUTHORS (màn classic)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/openalex_ranked_entity.dart';
import '../viewmodels/publication_viewmodel.dart';
import '../utils/count_format.dart';
import 'author_detail_screen.dart';

/// 4.6 Top Contributing Authors
class TopAuthorsScreen extends StatelessWidget {
  const TopAuthorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // [Merge resolved] Chọn feature/lab3: PublicationViewModel + rankedAuthors
    final provider = context.watch<PublicationViewModel>();
    final topAuthors = provider.rankedAuthors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Contributing Authors (OpenAlex)'),
      ),
      body: topAuthors.isEmpty
          ? const Center(child: Text('No author rankings from OpenAlex yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topAuthors.length,
              itemBuilder: (context, index) {
                final author = topAuthors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(
                      author.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${formatOpenAlexCount(author.count)}\nworks',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _openAuthor(context, provider, author),
                  ),
                );
              },
            ),
    );
  }

  void _openAuthor(
    BuildContext context,
    PublicationViewModel provider,
    OpenAlexRankedEntity author,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthorDetailScreen(
          author: author,
          provider: provider,
        ),
      ),
    );
  }
}
