// =============================================================================
// home_tab_screen.dart — TAB HOME
// =============================================================================
// Search + Recent Searches + Research Landscape (#6) + link màn cũ.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/insight_widgets.dart';
import '../widgets/research_landscape_grid.dart';
import 'domain_detail_screen.dart';
import 'overview_screen.dart';
import 'search_screen.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicationProvider>().loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch([String? preset]) async {
    if (preset != null) _searchController.text = preset;
    final topic = _searchController.text.trim();
    if (topic.isEmpty) return;

    final provider = context.read<PublicationProvider>();
    await provider.searchPublications(topic);
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: topic)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final insight = provider.trendInsight;
    final domains = provider.trendingAreas;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'Home',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Search topics · recent searches · research landscape',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            decoration: InputDecoration(
              hintText: 'Search research topics…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, size: 20),
                onPressed: () => _runSearch(),
              ),
            ),
          ),
          if (provider.recentSearches.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => provider.clearRecentSearches(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.recentSearches.map((topic) {
                return ActionChip(
                  label: Text(topic),
                  onPressed: () => _runSearch(topic),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Research Domains',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Domain size by publication volume',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 10),
          MockupCard(
            child: ResearchLandscapeGrid(
              domains: domains,
              onDomainTap: (domain) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DomainDetailScreen(domain: domain),
                ),
              ),
            ),
          ),
          if (provider.hasRealTrend) ...[
            const SizedBox(height: 12),
            MockupCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      insight.headline,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  GrowthLabel(percent: insight.periodGrowthPercent),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'Original screens (giữ nguyên)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          LandscapeTile(
            icon: Icons.dashboard_outlined,
            title: 'Global Research Overview',
            subtitle: 'Dashboard đầy đủ · Publications, Growth, Emerging',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OverviewScreen()),
            ),
          ),
          LandscapeTile(
            icon: Icons.explore_outlined,
            title: 'Explore Search',
            subtitle: 'Màn search cũ với topic snapshot & load more',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
