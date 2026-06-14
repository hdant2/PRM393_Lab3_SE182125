import 'package:flutter/material.dart';

import '../model/publication.dart';
import 'detail_screen.dart';

/// Màn hình hiển thị danh sách bài báo của một tác giả
class AuthorDetailScreen extends StatelessWidget {
  final String authorName;
  final List<Publication> publications;

  const AuthorDetailScreen({
    super.key,
    required this.authorName,
    required this.publications,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(authorName),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: publications.length,
        itemBuilder: (context, index) {
          final paper = publications[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                paper.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Year: ${paper.year}\n'
                'Citations: ${paper.citations}',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(
                      publication: paper,
                    ),
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