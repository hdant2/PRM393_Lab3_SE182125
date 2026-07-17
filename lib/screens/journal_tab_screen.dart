// =============================================================================
// journal_tab_screen.dart — TAB JOURNAL (Publications + Details)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// [Merge resolved] Chọn feature/lab3: import viewmodels thay vì providers
import '../viewmodels/publication_viewmodel.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../widgets/app_logo.dart';
import '../widgets/publication_card.dart';
import 'citation_leaders_screen.dart';
import 'top_papers_screen.dart';

class JournalTabScreen extends StatelessWidget {
  const JournalTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationViewModel>();
    final papers = provider.isGlobalScope
        ? provider.topPapersOpenAlex
        : provider.publications;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'Journal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              provider.isGlobalScope
                  ? 'Influential publications · tap for details'
                  : 'Publications for "${provider.currentTopic}"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: papers.isEmpty
                ? const Center(
                    child: Text(
                      'Loading publications from OpenAlex…',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      ...papers.map(
                        (paper) => PublicationCard(publication: paper),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'More from original app',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LandscapeTile(
                        icon: Icons.emoji_events_outlined,
                        title: 'Citation Leaders',
                        subtitle:
                            '${formatOpenAlexCount(provider.topPapersOpenAlex.length)} top cited · authors',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CitationLeadersScreen(),
                          ),
                        ),
                      ),
                      LandscapeTile(
                        icon: Icons.article_outlined,
                        title: 'Top Influential Papers',
                        subtitle: 'Danh sách bài cũ (TopPapersScreen)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TopPapersScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
