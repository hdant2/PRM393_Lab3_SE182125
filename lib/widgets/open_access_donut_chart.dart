import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/count_format.dart';

/// Donut Open Access — giống widget sidebar trên OpenAlex web.
class OpenAccessDonutChart extends StatelessWidget {
  final int openAccessCount;
  final int closedCount;

  const OpenAccessDonutChart({
    super.key,
    required this.openAccessCount,
    required this.closedCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = openAccessCount + closedCount;
    if (total <= 0) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No open access data',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      );
    }

    final percent = openAccessCount / total * 100;

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 44,
                    sections: [
                      PieChartSectionData(
                        value: openAccessCount.toDouble(),
                        color: AppColors.chartPrimary,
                        radius: 30,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: closedCount.toDouble(),
                        color: AppColors.chartTrack,
                        radius: 30,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'Open Access',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                  color: AppColors.chartPrimary,
                  label: 'Open Access',
                  count: openAccessCount,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  color: AppColors.chartTrack,
                  label: 'Closed',
                  count: closedCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Text(
          formatOpenAlexCount(count),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
