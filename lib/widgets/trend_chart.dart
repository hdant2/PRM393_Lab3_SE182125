// =============================================================================
// trend_chart.dart — BIỂU ĐỒ LINE TREND (fl_chart)
// =============================================================================
// Input: Map<int,int> năm → số bài (hoặc citations).
// Dùng ở: TrendScreen, GrowthScreen, Keywords tab, Author/Journal/Domain detail.
// =============================================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/count_format.dart';

/// Line chart — trục X theo thứ tự năm, tooltip khi chạm điểm
class TrendChart extends StatelessWidget {
  final Map<int, int> yearlyData;

  const TrendChart({
    super.key,
    required this.yearlyData,
  });

  @override
  Widget build(BuildContext context) {
    final years = yearlyData.keys.toList()..sort();

    if (years.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No trend data available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // Chuyển Map → FlSpot cho fl_chart
    final spots = <FlSpot>[];
    for (var i = 0; i < years.length; i++) {
      spots.add(FlSpot(i.toDouble(), yearlyData[years[i]]!.toDouble()));
    }

    final maxY = yearlyData.values.reduce((a, b) => a > b ? a : b).toDouble();
    final minY = yearlyData.values.reduce((a, b) => a < b ? a : b).toDouble();
    final yPadding = (maxY - minY) * 0.15;
    final chartMaxY = maxY + (yPadding > 0 ? yPadding : maxY * 0.1);
    final chartMinY = (minY - yPadding).clamp(0, minY).toDouble();
    final yInterval = _niceInterval(chartMaxY - chartMinY);
    final labelInterval = years.length <= 6 ? 1 : (years.length / 5).ceil();

    return SizedBox(
      height: 280,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (years.length - 1).toDouble(),
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= years.length) {
                    return null;
                  }
                  return LineTooltipItem(
                    '${years[index]}\n${formatOpenAlexCount(spot.y.toInt())}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: years.length > 2,
              curveSmoothness: 0.2,
              color: AppColors.textPrimary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: years.length <= 12,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.textPrimary,
                  strokeWidth: 0,
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 ||
                      index >= years.length ||
                      index % labelInterval != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${years[index]}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value < chartMinY || value > chartMaxY) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    formatOpenAlexCount(value.toInt()),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Chọn bước trục Y đẹp (1, 2, 5, 10 × 10^n)
  double _niceInterval(double range) {
    if (range <= 0) return 1;
    final raw = range / 4;
    final magnitude =
        _pow10(raw.floor().toString().length - 1).clamp(1, 1000000000);
    final normalized = raw / magnitude;
    double nice;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  double _pow10(int exponent) {
    var value = 1.0;
    for (var i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }
}
