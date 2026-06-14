import 'package:flutter/material.dart';

import '../model/publication.dart';

/// Màn hình hiển thị chi tiết một bài báo khoa học
class DetailScreen extends StatelessWidget {
  final Publication publication;

  const DetailScreen({
    super.key,
    required this.publication,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication Detail'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // TITLE
            // =====================================================
            Text(
              publication.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // =====================================================
            // BASIC INFORMATION
            // =====================================================
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Publication Year',
              value: publication.year.toString(),
            ),

            _buildInfoRow(
              icon: Icons.format_quote,
              label: 'Citation Count',
              value: publication.citations.toString(),
            ),

            _buildInfoRow(
              icon: Icons.menu_book,
              label: 'Journal',
              value: publication.journal,
            ),

            _buildInfoRow(
              icon: Icons.link,
              label: 'DOI',
              value: publication.doi.isEmpty
                  ? 'No DOI available'
                  : publication.doi,
            ),

            const SizedBox(height: 20),

            // =====================================================
// AUTHORS
// =====================================================

const Text(
  'Authors',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 8),

publication.authors.isEmpty
    ? const Text(
        'No authors available',
      )
    : Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: publication.authors
            .map(
              (author) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 4,
                ),
                child: Text(
                  '• $author',
                ),
              ),
            )
            .toList(),
      ),

const SizedBox(height: 20),

            // =====================================================
            // ABSTRACT
            // =====================================================
            const Text(
              'Abstract',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
  publication.abstractText,
  textAlign: TextAlign.justify,
  style: const TextStyle(
    height: 1.6,
    fontSize: 15,
  ),
)
          ],
        ),
      ),
    );
  }

  /// Widget tái sử dụng để hiển thị từng dòng thông tin
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),

          const SizedBox(width: 8),

          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}