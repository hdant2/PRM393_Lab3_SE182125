// =============================================================================
// keywords_tab_screen.dart — TAB KEYWORDS (Trends + Authors + Journals)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// [Merge resolved] Chọn feature/lab3: import viewmodels thay vì providers
import '../viewmodels/publication_viewmodel.dart';
import '../theme/app_theme.dart';
import '../utils/research_insights.dart';
import '../widgets/app_logo.dart';
import '../widgets/trend_chart.dart';
import 'growth_screen.dart';
import 'journals_analysis_screen.dart';
import 'keywords_overview_screen.dart';
import 'research_domains_screen.dart';
import 'research_leaders_screen.dart';

class KeywordsTabScreen extends StatelessWidget {
  const KeywordsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationViewModel>();
    final trend = provider.yearlyTrendFromOpenAlex;
    final insight = provider.trendInsight;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'Keywords',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Trends · top keywords · emerging · authors · journals',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Text(
            'Publication Growth',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            trend.isEmpty
                ? 'Loading trend…'
                : '${insight.startYear} → ${insight.endYear}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          MockupCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
            child: trend.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 140,
                        child: TrendChart(
                          yearlyData: trend,
                          overlayYearlyData: provider.citationsByYearOpenAlex,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        insight.headline,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (insight.periodGrowthPercent.abs() >= 1) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Research output changed '
                          '${ResearchInsights.formatGrowth(insight.periodGrowthPercent)} '
                          'since ${insight.startYear}.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          LandscapeTile(
            icon: Icons.tag_outlined,
            title: 'Keyword Overview',
            subtitle: 'Top research keywords and fastest growing topics',
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
            subtitle: 'Top authors by publication volume',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ResearchLeadersScreen(),
              ),
            ),
          ),
          LandscapeTile(
            icon: Icons.menu_book_outlined,
            title: 'Journal Rankings',
            subtitle: 'Top publication sources',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const JournalsAnalysisScreen(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Original analytics screens',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          LandscapeTile(
            icon: Icons.trending_up_outlined,
            title: 'Research Growth',
            subtitle: 'GrowthScreen · CAGR & domain growth bars',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GrowthScreen()),
            ),
          ),
          LandscapeTile(
            icon: Icons.hub_outlined,
            title: 'Research Domains',
            subtitle: 'Donut chart · ResearchDomainsScreen cũ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ResearchDomainsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
