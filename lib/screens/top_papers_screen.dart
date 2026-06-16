import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../utils/count_format.dart';
import 'detail_screen.dart';

/// 4.4 Top Influential Papers
class TopPapersScreen extends StatelessWidget {
  const TopPapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final topPapers = provider.topPapersOpenAlex;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Influential Papers (OpenAlex)'),
      ),
      body: topPapers.isEmpty
          ? const Center(child: Text('No publications from OpenAlex yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topPapers.length,
              itemBuilder: (context, index) {
                final paper = topPapers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(
                      paper.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Year: ${paper.year} · Journal: ${paper.journal}',
                    ),
                    trailing: Text(
                      '${formatOpenAlexCount(paper.citations)}\ncites',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(publication: paper),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
