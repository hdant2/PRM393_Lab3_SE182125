// =============================================================================
// research_leaders_screen.dart — TOP AUTHORS (#7)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/openalex_ranked_entity.dart';
// [Merge resolved] Chọn feature/lab3: import viewmodels thay vì providers
import '../viewmodels/publication_viewmodel.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import 'author_detail_screen.dart';
import 'top_authors_screen.dart';

class ResearchLeadersScreen extends StatelessWidget {
  const ResearchLeadersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationViewModel>();
    final authors = provider.dashboardRankedAuthors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Research Leaders'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TopAuthorsScreen()),
            ),
            child: const Text('Classic list'),
          ),
        ],
      ),
      body: authors.isEmpty
          ? const Center(
              child: Text(
                'Loading authors from OpenAlex…',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: authors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final author = authors[index];
                return _LeaderTile(
                  author: author,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthorDetailScreen(
                        author: author,
                        provider: provider,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _LeaderTile extends StatelessWidget {
  final OpenAlexRankedEntity author;
  final VoidCallback onTap;

  const _LeaderTile({required this.author, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatOpenAlexCount(author.count)} publications',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
