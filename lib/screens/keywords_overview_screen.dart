// =============================================================================
// keywords_overview_screen.dart — TOP KEYWORDS (#3) + EMERGING (#4)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/openalex_ranked_entity.dart';
import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/keyword_bar_chart.dart';
import 'domain_detail_screen.dart';

class KeywordsOverviewScreen extends StatelessWidget {
  const KeywordsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final keywords = provider.trendingAreas;
    final emerging = provider.growingTopicsOpenAlex;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Keyword Overview'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MockupCard(
            child: KeywordBarChart(
              title: 'Top Research Keywords',
              items: keywords.map((k) => k.entry).toList(),
              onItemTap: (name) {
                OpenAlexRankedEntity? domain;
                for (final item in keywords) {
                  if (item.name == name) {
                    domain = item;
                    break;
                  }
                }
                if (domain == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DomainDetailScreen(domain: domain!),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fastest Growing Topics',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Concept growth compared to earlier years',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          MockupCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: emerging.isEmpty
                ? const Text(
                    'Loading emerging topics from OpenAlex…',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Column(
                    children: emerging.take(6).map((topic) {
                      final domain = provider.rankedConceptById(topic.id) ??
                          OpenAlexRankedEntity(
                            id: topic.id,
                            name: topic.name,
                            count: 0,
                          );
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DomainDetailScreen(domain: domain),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  topic.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                topic.formattedGrowth,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
