import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/publication.dart';
import '../providers/publication_provider.dart';
import 'detail_screen.dart';

/// Màn hình hiển thị các bài báo có ảnh hưởng nhất
/// dựa trên số lượt trích dẫn
class TopPapersScreen extends StatelessWidget {
  const TopPapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    final topPapers = _getTopPapers(
      provider.publications,
    );

    final topic = provider.currentTopic;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Influential Papers'),
      ),
      body: topPapers.isEmpty
          ? const Center(
              child: Text(
                'Please search a topic first.',
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // CURRENT TOPIC INFO
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
                        '${topPapers.length} top papers displayed',
                      ),
                    ),
                  ),
                ),

                // =====================================================
                // TOP PAPERS LIST
                // =====================================================
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: topPapers.length,
                    itemBuilder: (context, index) {
                      final paper = topPapers[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            paper.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Year: ${paper.year}\n'
                            'Journal: ${paper.journal}',
                          ),
                          trailing: Text(
                            '${paper.citations}\nCites',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
                ),
              ],
            ),
    );
  }

  /// Lấy danh sách bài báo có citation cao nhất
  List<Publication> _getTopPapers(
    List<Publication> publications,
  ) {
    // =====================================================
    // STEP 1: Loại bỏ bài báo trùng ID
    // =====================================================
    final uniquePapers = <String, Publication>{};

    for (final paper in publications) {
      uniquePapers[paper.id] = paper;
    }

    // =====================================================
    // STEP 2: Chuyển Map thành List
    // =====================================================
    final sortedPapers = uniquePapers.values.toList();

    // =====================================================
    // STEP 3: Sắp xếp theo citation giảm dần
    // =====================================================
    sortedPapers.sort(
      (a, b) => b.citations.compareTo(
        a.citations,
      ),
    );

    // =====================================================
    // STEP 4: Lấy Top 10
    // =====================================================
    return sortedPapers.take(10).toList();
  }
}