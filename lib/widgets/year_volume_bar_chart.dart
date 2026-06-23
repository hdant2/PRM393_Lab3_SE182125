import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../utils/overview_time_range.dart';

/// Cột dọc theo năm — style sidebar Year trên OpenAlex web.
class YearVolumeBarChart extends StatelessWidget {
  final Map<int, int> yearlyData;
  final int maxYears;
  final bool isMonthly;
  final void Function(int year)? onYearTap;

  const YearVolumeBarChart({
    super.key,
    required this.yearlyData,
    this.maxYears = 14,
    this.isMonthly = false,
    this.onYearTap,
  });

  @override
  Widget build(BuildContext context) {
    if (yearlyData.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No ${isMonthly ? 'monthly' : 'yearly'} data',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final sorted = yearlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final slice = isMonthly
        ? sorted
        : (sorted.length <= maxYears
            ? sorted
            : sorted.sublist(sorted.length - maxYears));
    final keys = slice.map((e) => e.key).toList();
    final values = slice.map((e) => e.value).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b).toDouble();
    final labelInterval = isMonthly
        ? (keys.length <= 6 ? 1 : 2)
        : 1;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.15,
          barTouchData: BarTouchData(
            enabled: onYearTap != null,
            touchCallback: (event, response) {
              if (onYearTap == null || response?.spot == null) return;
              final index = response!.spot!.touchedBarGroupIndex;
              if (index < 0 || index >= keys.length) return;
              onYearTap!(keys[index]);
            },
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: maxY > 0 ? maxY / 4 : 1,
                getTitlesWidget: (value, meta) => Text(
                  formatOpenAlexCount(value.toInt()),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 ||
                      index >= keys.length ||
                      index % labelInterval != 0) {
                    return const SizedBox.shrink();
                  }
                  final label = isMonthly
                      ? monthShortLabel(keys[index])
                      : '${keys[index]}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    width: isMonthly ? 10 : 12,
                    color: AppColors.chartPrimary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
