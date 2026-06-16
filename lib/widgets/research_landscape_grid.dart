// =============================================================================
// research_landscape_grid.dart — RESEARCH LANDSCAPE (#6)
// =============================================================================
// Domain chips sized theo publication count — tab Home & Overview.

import 'package:flutter/material.dart';

import '../models/openalex_ranked_entity.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';

/// Research Landscape — domain chips theo tỉ lệ publication count.
class ResearchLandscapeGrid extends StatelessWidget {
  final List<OpenAlexRankedEntity> domains;
  final void Function(OpenAlexRankedEntity domain)? onDomainTap;

  const ResearchLandscapeGrid({
    super.key,
    required this.domains,
    this.onDomainTap,
  });

  @override
  Widget build(BuildContext context) {
    if (domains.isEmpty) {
      return const Text(
        'Loading research domains…',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }

    final top = domains.take(6).toList();
    final maxCount = top.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: top.map((domain) {
            final scale = (domain.count / maxCount).clamp(0.35, 1.0);
            final fontSize = 11.0 + (scale * 4);
            return Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onDomainTap == null ? null : () => onDomainTap!(domain),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 + (scale * 8),
                    vertical: 10 + (scale * 6),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                      width: scale > 0.7 ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        domain.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatOpenAlexCount(domain.count),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap a domain to explore papers, authors & journals',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
        ),
      ],
    );
  }
}
