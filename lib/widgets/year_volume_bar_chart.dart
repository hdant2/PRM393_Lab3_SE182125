import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import '../utils/overview_time_range.dart';
<<<<<<< HEAD

/// Cột dọc theo năm — style sidebar Year trên OpenAlex web.
class YearVolumeBarChart extends StatelessWidget {
=======
import 'chart_axis_layout.dart';
import 'chart_touch_banner.dart';
import 'scrollable_chart_frame.dart';

/// Cột dọc theo năm — cuộn ngang khi nhiều năm, nhãn đủ 2026.
class YearVolumeBarChart extends StatefulWidget {
>>>>>>> feature/lab3
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
<<<<<<< HEAD
  Widget build(BuildContext context) {
    if (yearlyData.isEmpty) {
=======
  State<YearVolumeBarChart> createState() => _YearVolumeBarChartState();
}

class _YearVolumeBarChartState extends State<YearVolumeBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.yearlyData.isEmpty) {
>>>>>>> feature/lab3
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
<<<<<<< HEAD
            'No ${isMonthly ? 'monthly' : 'yearly'} data',
=======
            'No ${widget.isMonthly ? 'monthly' : 'yearly'} data',
>>>>>>> feature/lab3
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

<<<<<<< HEAD
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
=======
    final sorted = widget.yearlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final slice = widget.isMonthly
        ? sorted
        : (sorted.length <= widget.maxYears
            ? sorted
            : sorted.sublist(sorted.length - widget.maxYears));
    final keys = slice.map((e) => e.key).toList();
    final values = slice.map((e) => e.value).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b).toDouble();
    final scrollable = ScrollableChartFrame.needsScroll(
      context,
      pointCount: keys.length,
      isMonthly: widget.isMonthly,
    );
    final chartWidth = scrollable
        ? ScrollableChartFrame.contentWidth(
            context,
            pointCount: keys.length,
            isMonthly: widget.isMonthly,
          )
        : ChartAxisLayout.viewportWidth(context);
    final layout = scrollable
        ? _scrollLayout(keys.length, widget.isMonthly)
        : ChartAxisLayout.fit(
            context,
            pointCount: keys.length,
            isMonthly: widget.isMonthly,
          );
    final chartHeight = 240.0 + (layout.rotateLabels ? 16.0 : 0.0);
    final showDeclineNote = _shouldShowDeclineNote(values);
    final selectedIndex = _selectedIndex;
    final bannerPrimary = selectedIndex != null &&
            selectedIndex >= 0 &&
            selectedIndex < keys.length
        ? '${keys[selectedIndex]}'
        : null;
    final bannerSecondary = selectedIndex != null &&
            selectedIndex >= 0 &&
            selectedIndex < values.length
        ? '${formatOpenAlexCount(values[selectedIndex])} papers'
        : 'Chạm cột để xem số bài theo năm';

    final chart = SizedBox(
      width: chartWidth,
      height: chartHeight,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.15,
          alignment: BarChartAlignment.spaceBetween,
          groupsSpace: layout.groupsSpace,
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: false,
            touchTooltipData: const BarTouchTooltipData(),
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions) return;
              final index = response?.spot?.touchedBarGroupIndex;
              if (index == null || index < 0 || index >= keys.length) return;
              setState(() => _selectedIndex = index);
              widget.onYearTap?.call(keys[index]);
>>>>>>> feature/lab3
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
<<<<<<< HEAD
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
=======
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: layout.leftAxisSize,
>>>>>>> feature/lab3
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
<<<<<<< HEAD
=======
                reservedSize: layout.bottomReserved,
>>>>>>> feature/lab3
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 ||
                      index >= keys.length ||
<<<<<<< HEAD
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
=======
                      index % layout.labelInterval != 0) {
                    return const SizedBox.shrink();
                  }
                  final label = widget.isMonthly
                      ? monthShortLabel(keys[index])
                      : '${keys[index]}';
                  final isEdge = index == 0 || index == keys.length - 1;
                  return buildChartAxisLabel(
                    text: label,
                    rotate: layout.rotateLabels,
                    labelWidth: isEdge ? 60 : (scrollable ? 52 : 36),
                    textAlign: chartAxisLabelAlign(
                      index: index,
                      count: keys.length,
>>>>>>> feature/lab3
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
<<<<<<< HEAD
                    width: isMonthly ? 10 : 12,
                    color: AppColors.chartPrimary,
=======
                    width: layout.barWidth,
                    color: _selectedIndex == i
                        ? AppColors.chartPrimary.withValues(alpha: 0.85)
                        : AppColors.chartPrimary,
>>>>>>> feature/lab3
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
<<<<<<< HEAD
=======

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartTouchBanner(
          primaryText: bannerPrimary,
          secondaryText: bannerSecondary,
        ),
        if (scrollable)
          ScrollableChartFrame(
            height: chartHeight,
            scrollable: true,
            scrollToEnd: true,
            child: chart,
          )
        else
          SizedBox(height: chartHeight, child: chart),
        if (showDeclineNote) ...[
          const SizedBox(height: 6),
          Text(
            'Chạm cột để xem số bài — năm gần đây thấp hơn đỉnh 2017–2020 nhưng vẫn có dữ liệu',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary.withValues(alpha: 0.95),
              height: 1.3,
            ),
          ),
        ],
        if (scrollable) const SizedBox(height: 2),
      ],
    );
  }

  static ChartAxisLayout _scrollLayout(int pointCount, bool isMonthly) {
    if (isMonthly) {
      return ChartAxisLayout(
        leftAxisSize: 40,
        barWidth: 14,
        groupsSpace: 10,
        labelInterval: pointCount > 8 ? 2 : 1,
        rotateLabels: false,
        shortYearLabels: false,
        bottomReserved: 38,
      );
    }
    return const ChartAxisLayout(
      leftAxisSize: 40,
      barWidth: 22,
      groupsSpace: 14,
      labelInterval: 1,
      rotateLabels: false,
      shortYearLabels: false,
      bottomReserved: 40,
    );
  }

  static bool _shouldShowDeclineNote(List<int> values) {
    if (values.length < 4) return false;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return false;
    final tail = values.sublist(values.length - 3);
    final tailMax = tail.reduce((a, b) => a > b ? a : b);
    return tailMax > 0 && tailMax < maxVal * 0.08;
>>>>>>> feature/lab3
  }
}
