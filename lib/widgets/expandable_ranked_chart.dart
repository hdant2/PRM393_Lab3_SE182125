import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hiển thị top [previewCount] mục; bấm "Show all" để mở rộng.
class ExpandableRankedChart extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<MapEntry<String, int>> items;
  final int previewCount;
  final Widget Function(List<MapEntry<String, int>> visibleItems) chartBuilder;

  const ExpandableRankedChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.chartBuilder,
    this.previewCount = 5,
  });

  @override
  State<ExpandableRankedChart> createState() => _ExpandableRankedChartState();
}

class _ExpandableRankedChartState extends State<ExpandableRankedChart> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final canExpand = widget.items.length > widget.previewCount;
    final visibleItems = _showAll || !canExpand
        ? widget.items
        : widget.items.take(widget.previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 14),
        widget.chartBuilder(visibleItems),
        if (canExpand) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(_showAll ? 'Show less' : 'Show all'),
            ),
          ),
        ],
      ],
    );
  }
}
