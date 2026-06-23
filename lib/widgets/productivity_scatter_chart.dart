import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/openalex_impact_profile.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';

/// Scatter chart: works (productivity) vs citations (impact).
class ProductivityScatterChart extends StatelessWidget {
  final List<OpenAlexImpactProfile> profiles;
  final void Function(OpenAlexImpactProfile profile)? onPointTap;

  const ProductivityScatterChart({
    super.key,
    required this.profiles,
    this.onPointTap,
  });

  @override
  Widget build(BuildContext context) {
    final points = profiles
        .where((profile) => profile.worksCount > 0 && profile.citedByCount > 0)
        .toList();
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No impact data available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final maxWorks = points
        .map((profile) => profile.worksCount)
        .reduce((a, b) => a > b ? a : b);
    final maxCitations = points
        .map((profile) => profile.citedByCount)
        .reduce((a, b) => a > b ? a : b);
    final chartMaxX = (maxWorks * 1.15).clamp(10.0, double.infinity);
    final chartMaxY = (maxCitations * 1.15).clamp(10.0, double.infinity);

    final spots = <ScatterSpot>[];
    for (var index = 0; index < points.length; index++) {
      final profile = points[index];
      spots.add(
        ScatterSpot(
          profile.worksCount.toDouble(),
          profile.citedByCount.toDouble(),
          dotPainter: FlDotCirclePainter(
            radius: 5,
            color: AppColors.chartPrimary.withValues(alpha: 0.85),
            strokeWidth: 1,
            strokeColor: AppColors.chartPrimary,
          ),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: ScatterChart(
        ScatterChartData(
          minX: 0,
          maxX: chartMaxX,
          minY: 0,
          maxY: chartMaxY,
          scatterSpots: spots,
          scatterTouchData: ScatterTouchData(
            enabled: onPointTap != null,
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions) return;
              final spot = response?.touchedSpot;
              if (spot == null) return;
              final index = spot.spotIndex;
              if (index < 0 || index >= points.length) return;
              onPointTap?.call(points[index]);
            },
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (_) => FlLine(
              color: AppColors.border.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text(
                'Works (productivity)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: chartMaxX / 4,
                getTitlesWidget: (value, meta) => Text(
                  formatOpenAlexCount(value.round()),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                'Citations (impact)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: chartMaxY / 4,
                getTitlesWidget: (value, meta) => Text(
                  formatOpenAlexCount(value.round()),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
