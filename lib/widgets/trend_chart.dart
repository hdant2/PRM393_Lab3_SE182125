import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../utils/overview_time_range.dart';

class _TrendChartScale {
  const _TrendChartScale({
    required this.years,
    required this.spots,
    required this.overlaySpots,
    required this.overlayValues,
    required this.chartMinY,
    required this.chartMaxY,
    required this.yInterval,
    required this.labelInterval,
    required this.isMonthly,
  });

  final List<int> years;
  final List<FlSpot> spots;
  final List<FlSpot> overlaySpots;
  final List<int> overlayValues;
  final double chartMinY;
  final double chartMaxY;
  final double yInterval;
  final int labelInterval;
  final bool isMonthly;

  bool get hasOverlay => overlaySpots.isNotEmpty;

  String labelForIndex(int index) {
    if (index < 0 || index >= years.length) return '';
    return isMonthly ? monthShortLabel(years[index]) : '${years[index]}';
  }
}

/// Line chart — publication trend with optional citation overlay (normalized).
class TrendChart extends StatelessWidget {
  final Map<int, int> yearlyData;

  /// Second series (e.g. citations by year) — dashed line, shape-normalized.
  final Map<int, int>? overlayYearlyData;
  final bool isMonthly;

  const TrendChart({
    super.key,
    required this.yearlyData,
    this.overlayYearlyData,
    this.isMonthly = false,
  });

  @override
  Widget build(BuildContext context) {
    final scale = _buildScale(yearlyData, overlayYearlyData);
    if (scale == null) {
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

    return SizedBox(
      height: 280,
      child: LineChart(_buildChartData(scale)),
    );
  }

  _TrendChartScale? _buildScale(
    Map<int, int> data,
    Map<int, int>? overlay,
  ) {
    final years = data.keys.toList()..sort();
    if (years.isEmpty) {
      return null;
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < years.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[years[i]]!.toDouble()));
    }

    final maxY = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final minY = data.values.reduce((a, b) => a < b ? a : b).toDouble();
    final yPadding = (maxY - minY) * 0.15;
    final chartMaxY = maxY + (yPadding > 0 ? yPadding : maxY * 0.1);
    final chartMinY = (minY - yPadding).clamp(0, minY).toDouble();

    final overlayValues = <int>[];
    final overlaySpots = <FlSpot>[];
    if (overlay != null && overlay.isNotEmpty) {
      for (var i = 0; i < years.length; i++) {
        overlayValues.add(overlay[years[i]] ?? 0);
      }
      final overlayMax = overlayValues
          .fold<int>(0, (max, value) => value > max ? value : max)
          .toDouble();
      if (overlayMax > 0) {
        for (var i = 0; i < years.length; i++) {
          overlaySpots.add(
            FlSpot(
              i.toDouble(),
              overlayValues[i] / overlayMax * chartMaxY,
            ),
          );
        }
      }
    }

    return _TrendChartScale(
      years: years,
      spots: spots,
      overlaySpots: overlaySpots,
      overlayValues: overlayValues,
      chartMinY: chartMinY,
      chartMaxY: chartMaxY,
      yInterval: _niceInterval(chartMaxY - chartMinY),
      labelInterval: isMonthly
          ? (years.length <= 6 ? 1 : 2)
          : (years.length <= 6 ? 1 : (years.length / 5).ceil()),
      isMonthly: isMonthly,
    );
  }

  LineChartData _buildChartData(_TrendChartScale scale) {
    return LineChartData(
      minX: 0,
      maxX: (scale.years.length - 1).toDouble(),
      minY: scale.chartMinY,
      maxY: scale.chartMaxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: scale.yInterval,
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
              if (index < 0 || index >= scale.years.length) {
                return null;
              }
              final year = scale.years[index];
              final label = scale.labelForIndex(index);
              final isOverlay = spot.barIndex == 1;
              if (isOverlay) {
                if (index >= scale.overlayValues.length) return null;
                return LineTooltipItem(
                  '$label citations\n${formatOpenAlexCount(scale.overlayValues[index])}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }
              return LineTooltipItem(
                '$label papers\n${formatOpenAlexCount(spot.y.toInt())}',
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
          spots: scale.spots,
          isCurved: scale.years.length > 2,
          curveSmoothness: 0.25,
          color: AppColors.chartPrimary,
          barWidth: 3,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.chartPrimary.withValues(alpha: 0.28),
                AppColors.chartPrimary.withValues(alpha: 0.02),
              ],
            ),
          ),
          dotData: FlDotData(
            show: scale.years.length <= 12,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: AppColors.chartPrimary,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
        ),
        if (scale.hasOverlay)
          LineChartBarData(
            spots: scale.overlaySpots,
            isCurved: scale.years.length > 2,
            curveSmoothness: 0.25,
            color: AppColors.chartSecondary,
            barWidth: 2,
            dashArray: const [6, 4],
            dotData: const FlDotData(show: false),
          ),
      ],
      titlesData: _buildTitles(scale),
    );
  }

  FlTitlesData _buildTitles(_TrendChartScale scale) {
    return FlTitlesData(
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
                index >= scale.years.length ||
                index % scale.labelInterval != 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                scale.labelForIndex(index),
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
          interval: scale.yInterval,
          getTitlesWidget: (value, meta) {
            if (value < scale.chartMinY || value > scale.chartMaxY) {
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
    );
  }

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
