// Tab Overview — UI gốc mockup + bổ sung thầy (KHÔNG xóa phần cũ)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/openalex_ranked_entity.dart';
import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../widgets/app_logo.dart';
import '../widgets/error_banner.dart';
import '../widgets/research_landscape_grid.dart';
import 'author_detail_screen.dart';
import 'citation_leaders_screen.dart';
import 'detail_screen.dart';
import 'domain_detail_screen.dart';
import 'growth_screen.dart';
import 'journal_detail_screen.dart';
import 'journals_analysis_screen.dart';
import 'keywords_overview_screen.dart';
import 'research_domains_screen.dart';
import 'research_leaders_screen.dart';
/// Overview / Dashboard — màn chính theo mockup JournalAI
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    return SafeArea(
      child: Column(
        children: [
          const JournalAiAppBar(showRefresh: true, showBell: true),
          _OverviewBody(provider: provider),
        ],
      ),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  final PublicationProvider provider;

  const _OverviewBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isDashboardLoading && !provider.hasData) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (provider.errorMessage != null && !provider.hasData) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorBanner(
            message: provider.errorMessage!,
            onRetry: () => provider.loadDefaultDashboard(),
          ),
        ),
      );
    }

    if (!provider.hasData) {
      return const Expanded(
        child: Center(child: Text('Loading research data...')),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => provider.refreshCurrentAnalysis(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ErrorBanner(
                  message: provider.errorMessage!,
                  onRetry: () => provider.refreshCurrentAnalysis(),
                ),
              ),
                    const Text(
                      'Global Research Overview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    MockupCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatOpenAlexCount(
                                        provider.totalOnOpenAlex,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                      ),
                                    ),
                                    const Text(
                                      'Publications',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Influential works since 2015 · OpenAlex',
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GrowthBadge(
                                percent: provider.landscapePulse.yoyGrowthPercent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              StatColumn(
                                label: 'Average Citations',
                                value: provider.averageCitationOpenAlex
                                    .toStringAsFixed(1),
                                hint: 'top 100 avg',
                              ),
                              StatColumn(
                                label: 'Peak Year',
                                value: provider.landscapePulse.peakYear > 0
                                    ? '${provider.landscapePulse.peakYear}'
                                    : 'N/A',
                                hint: 'most papers',
                              ),
                              StatColumn(
                                label: 'Coverage',
                                value: '2015–${DateTime.now().year}',
                                hint: 'years',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _KeyResearchInsightsSection(provider: provider),
                    const SizedBox(height: 28),
                    const Text(
                      'Research Domains Map',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap a domain to explore its research profile',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    MockupCard(
                      child: ResearchLandscapeGrid(
                        domains: provider.trendingAreas,
                        onDomainTap: (domain) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DomainDetailScreen(domain: domain),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Research Landscape',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LandscapeTile(
                      icon: Icons.trending_up_outlined,
                      title: 'Research Growth',
                      subtitle: 'Publication trends over time',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GrowthScreen(),
                        ),
                      ),
                    ),
                    LandscapeTile(
                      icon: Icons.emoji_events_outlined,
                      title: 'Citation Leaders',
                      subtitle: 'Most cited papers and authors',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CitationLeadersScreen(),
                        ),
                      ),
                    ),
                    LandscapeTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Publication Sources',
                      subtitle: 'Top journals and venues',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JournalsAnalysisScreen(),
                        ),
                      ),
                    ),
                    LandscapeTile(
                      icon: Icons.hub_outlined,
                      title: 'Research Domains',
                      subtitle: 'Field distribution and hot topics',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResearchDomainsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LandscapeTile(
                      icon: Icons.tag_outlined,
                      title: 'Keyword Overview',
                      subtitle: 'Top keywords and emerging topics',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KeywordsOverviewScreen(),
                        ),
                      ),
                    ),
                    LandscapeTile(
                      icon: Icons.person_outline,
                      title: 'Research Leaders',
                      subtitle: 'Authors with the most publications',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResearchLeadersScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (provider.growingTopicsOpenAlex.isNotEmpty) ...[
                      const Text(
                        'Emerging Topics',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Concept growth · tap to explore domain',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      MockupCard(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Column(
                          children: provider.growingTopicsOpenAlex
                              .take(5)
                              .map(
                                (topic) => InkWell(
                                  onTap: () {
                                    final domain = provider.rankedConceptById(
                                          topic.id,
                                        ) ??
                                        OpenAlexRankedEntity(
                                          id: topic.id,
                                          name: topic.name,
                                          count: 0,
                                        );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DomainDetailScreen(
                                          domain: domain,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        const Text(
                                          '🔥',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                topic.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const Text(
                                                'growth vs early period',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              topic.formattedGrowth,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Text(
                                              'growth',
                                              style: TextStyle(
                                                color: AppColors.textTertiary,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: AppColors.textTertiary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}

class _KeyResearchInsightsSection extends StatelessWidget {
  final PublicationProvider provider;

  const _KeyResearchInsightsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.topJournalsOpenAlex.isEmpty &&
        provider.topAuthorsOpenAlex.isEmpty &&
        provider.topPapersOpenAlex.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        MockupCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Key Research Insights',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dashboard summary · OpenAlex',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              if (provider.topJournalsOpenAlex.isNotEmpty)
                _DashboardInsightRow(
                  label: 'Top Journal',
                  value: provider.topJournalsOpenAlex.first.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalDetailScreen(
                        journal: provider.topJournalsOpenAlex.first,
                        provider: provider,
                      ),
                    ),
                  ),
                ),
              if (provider.topAuthorsOpenAlex.isNotEmpty)
                _DashboardInsightRow(
                  label: 'Top Author',
                  value: provider.topAuthorsOpenAlex.first.name,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthorDetailScreen(
                        author: provider.topAuthorsOpenAlex.first,
                        provider: provider,
                      ),
                    ),
                  ),
                ),
              if (provider.topPapersOpenAlex.isNotEmpty)
                _DashboardInsightRow(
                  label: 'Most Influential Paper',
                  value: provider.topPapersOpenAlex.first.title,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(
                        publication: provider.topPapersOpenAlex.first,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardInsightRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DashboardInsightRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
