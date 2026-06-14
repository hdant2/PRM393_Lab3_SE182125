import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/publication.dart';
import '../providers/publication_provider.dart';
import '../widgets/trend_chart.dart';

/// Màn hình phân tích xu hướng xuất bản theo năm
class TrendScreen extends StatelessWidget {
  const TrendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    final publications = provider.publications;
    final topic = provider.currentTopic;

    final yearlyData = _groupPublicationsByYear(publications);
    final yearRange = _getYearRange(yearlyData);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication Trend Analysis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: publications.isEmpty
            ? const Center(
                child: Text(
                  'Please search a topic first to view trend analysis.',
                ),
              )
            
            : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =====================================================
                  // CURRENT TOPIC SUMMARY
                  // =====================================================
                  Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      leading: const Icon(
                        Icons.show_chart,
                        color: Colors.blue,
                      ),
                      title: Text(
                        'Topic: $topic',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${publications.length} publications analyzed\n'
                        'Year range: $yearRange',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =====================================================
                  // TREND CHART
                  // =====================================================
                  const Text(
                    'Publication Trend by Year',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TrendChart(yearlyData: yearlyData),

                  const SizedBox(height: 20),

                  // =====================================================
                  // YEARLY SUMMARY
                  // =====================================================
                  const Text(
                    'Yearly Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                    
                      ..._sortYearsByPaperCount(yearlyData).map((entry) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text('Year: ${entry.key}'),
                            trailing: Text(
                              '${entry.value} papers',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    
                ],
              ),
      ),
      ),
    );
  }

  /// Group danh sách publications theo năm xuất bản
  Map<int, int> _groupPublicationsByYear(
    List<Publication> publications,
  ) {
    final Map<int, int> yearlyData = {};

    for (final publication in publications) {
      if (publication.year == 0) {
        continue;
      }

      yearlyData[publication.year] =
          (yearlyData[publication.year] ?? 0) + 1;
    }

    return Map.fromEntries(
      yearlyData.entries.toList()
        ..sort(
          (a, b) => a.key.compareTo(b.key),
        ),
    );
  }

  /// Lấy khoảng năm nhỏ nhất và lớn nhất
  String _getYearRange(
    Map<int, int> yearlyData,
  ) {
    if (yearlyData.isEmpty) {
      return 'N/A';
    }

    final years = yearlyData.keys.toList()..sort();

    return '${years.first} - ${years.last}';
  }


  /// Sắp xếp năm theo số lượng bài báo giảm dần
List<MapEntry<int, int>> _sortYearsByPaperCount(
  Map<int, int> yearlyData,
) {
  final entries = yearlyData.entries.toList();

  entries.sort((a, b) {

    // So sánh số paper trước
    final paperCompare =
        b.value.compareTo(a.value);

    if (paperCompare != 0) {
      return paperCompare;
    }

    // Nếu bằng nhau thì năm mới hơn lên trước
    return b.key.compareTo(a.key);
  });

  return entries;
}
}