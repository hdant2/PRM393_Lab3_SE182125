import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../utils/overview_time_range.dart';
// [Merge resolved] Chọn feature/lab3: Thêm import cho chart axis layout, touch banner, scrollable chart frame
import 'chart_axis_layout.dart';
import 'chart_touch_banner.dart';
import 'scrollable_chart_frame.dart';

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
    // [Merge resolved] Chọn feature/lab3: Dùng if-return thay vì ternary
    if (isMonthly) return monthShortLabel(years[index]);
    return '${years[index]}';
  }
}

/// Line chart — publication trend with optional citation overlay (normalized).
// [Merge resolved] Chọn feature/lab3: StatefulWidget với _selectedIndex
class TrendChart extends StatefulWidget {
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
  // [Merge resolved] Chọn feature/lab3: Tạo _TrendChartState với _selectedIndex
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    // [Merge resolved] Chọn feature/lab3: Sử dụng widget.yearlyData, widget.overlayYearlyData
    final scale = _buildScale(widget.yearlyData, widget.overlayYearlyData);
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

    // [Merge resolved] Chọn feature/lab3: ScrollableChartFrame, ChartTouchBanner, touch interaction
    final scrollable = ScrollableChartFrame.needsScroll(
      context,
      pointCount: scale.years.length,
      isMonthly: widget.isMonthly,
    );
    final chartWidth = ScrollableChartFrame.contentWidth(
      context,
      pointCount: scale.years.length,
      isMonthly: widget.isMonthly,
    );
    final showDeclineNote = _shouldShowDeclineNote(widget.yearlyData);
    final banner = _buildTouchBanner(scale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartTouchBanner(
          primaryText: banner.$1,
          secondaryText: banner.$2,
        ),
        ScrollableChartFrame(
          height: 300,
          scrollable: scrollable,
          scrollToEnd: scrollable,
          child: SizedBox(
            width: chartWidth,
            height: 300,
            child: LineChart(_buildChartData(scale)),
          ),
        ),
        if (showDeclineNote) ...[
          const SizedBox(height: 4),
          Text(
            'Chạm điểm trên đường để xem số bài — năm gần đây thấp hơn đỉnh nhưng vẫn có dữ liệu',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary.withValues(alpha: 0.95),
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  (String?, String?) _buildTouchBanner(_TrendChartScale scale) {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= scale.years.length) {
      return (null, 'Chạm điểm để xem số bài theo năm');
    }
    final year = scale.labelForIndex(index);
    final papers = formatOpenAlexCount(scale.spots[index].y.toInt());
    final overlay = scale.hasOverlay && index < scale.overlayValues.length
        ? formatOpenAlexCount(scale.overlayValues[index])
        : null;
    return (
      year,
      overlay != null ? '$papers papers · $overlay citations' : '$papers papers',
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

    final spots = _buildSpots(years, data);
    final maxY = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final minY = data.values.reduce((a, b) => a < b ? a : b).toDouble();
    final yPadding = (maxY - minY) * 0.12;
    final chartMaxY = maxY + (yPadding > 0 ? yPadding : maxY * 0.1);
    const chartMinY = 0.0;

    final (overlaySpots, overlayValues) = _buildOverlaySpots(
      years: years,
      overlay: overlay,
      chartMaxY: chartMaxY,
    );

    int labelInterval;
    if (widget.isMonthly) {
      labelInterval = years.length > 8 ? 2 : 1;
    } else {
      labelInterval = 1;
    }

    return _TrendChartScale(
      years: years,
      spots: spots,
      overlaySpots: overlaySpots,
      overlayValues: overlayValues,
      chartMinY: chartMinY,
      chartMaxY: chartMaxY,
      yInterval: _niceInterval(chartMaxY - chartMinY),
      labelInterval: labelInterval,
      isMonthly: widget.isMonthly,
    );
  }

  List<FlSpot> _buildSpots(List<int> years, Map<int, int> data) {
    return [
      for (var i = 0; i < years.length; i++)
        FlSpot(i.toDouble(), data[years[i]]!.toDouble()),
    ];
  }

  (List<FlSpot>, List<int>) _buildOverlaySpots({
    required List<int> years,
    required Map<int, int>? overlay,
    required double chartMaxY,
  }) {
    if (overlay == null || overlay.isEmpty) {
      return (const [], <int>[]);
    }

    final overlayValues = <int>[];
    for (var i = 0; i < years.length; i++) {
      overlayValues.add(overlay[years[i]] ?? 0);
    }

    final overlayMax = overlayValues
        .fold<int>(0, (max, value) => value > max ? value : max)
        .toDouble();
    if (overlayMax <= 0) {
      return (const [], overlayValues);
    }

    final overlaySpots = [
      for (var i = 0; i < years.length; i++)
        FlSpot(i.toDouble(), overlayValues[i] / overlayMax * chartMaxY),
    ];
    return (overlaySpots, overlayValues);
  }

  LineChartData _buildChartData(_TrendChartScale scale) {
    // [Merge resolved] Chọn feature/lab3: trailingPad, clipData
    final trailingPad = widget.isMonthly ? 0.0 : 0.55;
    return LineChartData(
      clipData: const FlClipData.none(),
      minX: 0,
      maxX: (scale.years.length - 1).toDouble() + trailingPad,
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
        // [Merge resolved] Chọn feature/lab3: touchCallback thay vì touchTooltipData
        handleBuiltInTouches: false,
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions) return;
          final spots = response?.lineBarSpots;
          if (spots == null || spots.isEmpty) return;
          final index = spots.firstWhere(
            (spot) => spot.barIndex == 0,
            orElse: () => spots.first,
          ).x.toInt();
          if (index < 0 || index >= scale.years.length) return;
          setState(() => _selectedIndex = index);
        },
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
            // [Merge resolved] Chọn feature/lab3: Selected dot highlighting
            getDotPainter: (spot, percent, bar, index) {
              final selected = _selectedIndex == index;
              return FlDotCirclePainter(
                radius: selected ? 6 : 4,
                color: AppColors.chartPrimary,
                strokeWidth: selected ? 2 : 1.5,
                strokeColor: Colors.white,
              );
            },
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
          // [Merge resolved] Chọn feature/lab3: reservedSize=40
          reservedSize: 40,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 ||
                index >= scale.years.length ||
                index % scale.labelInterval != 0) {
              return const SizedBox.shrink();
            }
            // [Merge resolved] Chọn feature/lab3: Edge handling, chartAxisLabelAlign, overflow
            final isEdge = index == 0 || index == scale.years.length - 1;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: isEdge ? 60 : 52,
                child: Text(
                  scale.labelForIndex(index),
                  textAlign: chartAxisLabelAlign(
                    index: index,
                    count: scale.years.length,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          // [Merge resolved] Chọn feature/lab3: reservedSize dùng ScrollableChartFrame.leftAxisSize
          reservedSize: ScrollableChartFrame.leftAxisSize + 4,
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

  static bool _shouldShowDeclineNote(Map<int, int> data) {
    if (data.length < 4) return false;
    final values = data.values.toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return false;
    final sorted = data.keys.toList()..sort();
    final tail = sorted.sublist(sorted.length - 3).map((y) => data[y]!).toList();
    final tailMax = tail.reduce((a, b) => a > b ? a : b);
    return tailMax > 0 && tailMax < maxVal * 0.08;
  }
}
