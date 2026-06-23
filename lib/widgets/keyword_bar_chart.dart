// =============================================================================
// keyword_bar_chart.dart — BAR CHART NGANG CHO KEYWORDS (#3)
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/count_format.dart';

/// Bar chart ngang cho Top Keywords / Top Journals (diagram #3, #14).
class KeywordBarChart extends StatelessWidget {
  final String title;
  final String valueLabel;
  final List<MapEntry<String, int>> items;
  final void Function(String name)? onItemTap;
  final bool showFooter;

  const KeywordBarChart({
    super.key,
    required this.title,
    required this.items,
    this.valueLabel = 'publications',
    this.onItemTap,
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = items
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
        ],
        ...items.map((entry) {
          final ratio = entry.value / maxValue;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onItemTap == null ? null : () => onItemTap!(entry.key),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 108,
                        child: Text(
                          entry.key,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.chartTrack,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio.clamp(0.06, 1.0),
                              child: Container(
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppColors.chartPrimary,
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatOpenAlexCount(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (onItemTap != null) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (showFooter) ...[
          const SizedBox(height: 4),
          Text(
            'Bar length = $valueLabel · OpenAlex',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}
