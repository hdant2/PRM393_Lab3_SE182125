import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Khung cuộn ngang cho biểu đồ nhiều điểm (năm/tháng).
class ScrollableChartFrame extends StatefulWidget {
  final double height;
  final bool scrollable;
  final bool scrollToEnd;
  final Widget child;

  const ScrollableChartFrame({
    super.key,
    required this.height,
    required this.scrollable,
    required this.child,
    this.scrollToEnd = false,
  });

  static const double leftAxisSize = 40;
  /// Khoảng trống bên phải để nhãn năm cuối (vd. 2026) không bị cắt.
  static const double endPadding = 56;
  static const double trailingLabelPad = 40;

  static double slotWidth({required bool isMonthly}) => isMonthly ? 44 : 76;

  static double viewportWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width - 80;

  static double contentWidth(
    BuildContext context, {
    required int pointCount,
    required bool isMonthly,
  }) {
    final viewport = viewportWidth(context);
    final content = pointCount * slotWidth(isMonthly: isMonthly) +
        leftAxisSize +
        endPadding +
        (isMonthly ? 0 : trailingLabelPad);
    return content > viewport ? content : viewport;
  }

  static bool needsScroll(
    BuildContext context, {
    required int pointCount,
    required bool isMonthly,
  }) {
    if (pointCount <= 6) return false;
    final viewport = viewportWidth(context);
    final content = pointCount * slotWidth(isMonthly: isMonthly) +
        leftAxisSize +
        endPadding +
        (isMonthly ? 0 : trailingLabelPad);
    return content > viewport;
  }

  @override
  State<ScrollableChartFrame> createState() => _ScrollableChartFrameState();
}

class _ScrollableChartFrameState extends State<ScrollableChartFrame> {
  final ScrollController _scrollController = ScrollController();
  bool _didScrollToEnd = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEndIfNeeded() {
    if (!widget.scrollToEnd || _didScrollToEnd || !_scrollController.hasClients) {
      return;
    }
    _didScrollToEnd = true;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.scrollable) {
      return SizedBox(height: widget.height, child: widget.child);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEndIfNeeded());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: widget.child,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '← Kéo ngang để xem đủ các năm',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
