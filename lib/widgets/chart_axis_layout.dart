import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bố cục trục X tự co giãn để hiện đủ mọi năm/tháng trên 1 màn hình.
class ChartAxisLayout {
  const ChartAxisLayout({
    required this.leftAxisSize,
    required this.barWidth,
    required this.groupsSpace,
    required this.labelInterval,
    required this.rotateLabels,
    required this.shortYearLabels,
    required this.bottomReserved,
  });

  final double leftAxisSize;
  final double barWidth;
  final double groupsSpace;
  final int labelInterval;
  final bool rotateLabels;
  final bool shortYearLabels;
  final double bottomReserved;

  static double viewportWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width - 72;

  static ChartAxisLayout fit(
    BuildContext context, {
    required int pointCount,
    required bool isMonthly,
  }) {
    const leftAxis = 40.0;
    final viewport = viewportWidth(context);
    final slot = (viewport - leftAxis) / math.max(pointCount, 1);

    if (isMonthly) {
      final crowded = pointCount > 8;
      return ChartAxisLayout(
        leftAxisSize: leftAxis,
        barWidth: (slot * 0.55).clamp(6.0, 14.0),
        groupsSpace: (slot * 0.25).clamp(2.0, 12.0),
        labelInterval: crowded ? 2 : 1,
        rotateLabels: pointCount > 10,
        shortYearLabels: false,
        bottomReserved: pointCount > 10 ? 46 : 34,
      );
    }

    // Luôn hiện đủ năm: 2026 (không rút '26).
    final short = false;
    final rotate = pointCount > 10 && !isMonthly;
    return ChartAxisLayout(
      leftAxisSize: leftAxis,
      barWidth: (slot * 0.48).clamp(5.0, 16.0),
      groupsSpace: (slot * 0.18).clamp(2.0, 12.0),
      labelInterval: 1,
      rotateLabels: rotate,
      shortYearLabels: short,
      bottomReserved: rotate ? 52 : 40,
    );
  }

  String formatYear(int year) {
    if (!shortYearLabels) return '$year';
    final yy = year % 100;
    return "'${yy.toString().padLeft(2, '0')}";
  }
}

Widget buildChartAxisLabel({
  required String text,
  required bool rotate,
  double labelWidth = 36,
  TextAlign textAlign = TextAlign.center,
}) {
  const style = TextStyle(
    fontSize: 10,
    color: AppColors.textSecondary,
  );

  if (!rotate) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: labelWidth,
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: 1,
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.only(top: 2),
    child: SizedBox(
      width: labelWidth,
      height: 44,
      child: Transform.rotate(
        angle: -0.65,
        alignment: Alignment.topCenter,
        child: Text(text, style: style, textAlign: textAlign),
      ),
    ),
  );
}

TextAlign chartAxisLabelAlign({
  required int index,
  required int count,
}) {
  if (count <= 1) return TextAlign.center;
  if (index == 0) return TextAlign.left;
  if (index == count - 1) return TextAlign.right;
  return TextAlign.center;
}
