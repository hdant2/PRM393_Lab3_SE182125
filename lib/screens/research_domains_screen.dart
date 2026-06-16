import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/openalex_ranked_entity.dart';
import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../widgets/app_logo.dart';
import 'domain_detail_screen.dart';

class ResearchDomainsScreen extends StatelessWidget {
  const ResearchDomainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final domains = provider.trendingAreas;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Research Domains'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MockupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Domain Distribution',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'By Publications · OpenAlex concepts',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                DomainDonutChart(domains: domains),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Top Domains',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (domains.isEmpty)
            const Text(
              'No domain data yet.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...domains.asMap().entries.map(
              (entry) => _DomainListTile(
                rank: entry.key + 1,
                domain: entry.value,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DomainDetailScreen(domain: entry.value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DomainListTile extends StatelessWidget {
  final OpenAlexRankedEntity domain;
  final int rank;
  final VoidCallback onTap;

  const _DomainListTile({
    required this.domain,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    domain.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatOpenAlexCount(domain.count)} publications',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
