import 'package:flutter/material.dart';

import '../models/research_insight.dart';
import '../theme/app_theme.dart';
import '../utils/research_insights.dart';
import 'app_logo.dart';

class InsightSection extends StatelessWidget {
  final String emoji;
  final String title;
  final String? insight;
  final Widget child;

  const InsightSection({
    super.key,
    required this.emoji,
    required this.title,
    this.insight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (insight != null && insight!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            insight!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class InsightCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const InsightCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return MockupCard(padding: padding, child: child);
  }
}

class GrowthLabel extends StatelessWidget {
  final double percent;

  const GrowthLabel({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Text(
      ResearchInsights.formatGrowth(percent),
      style: TextStyle(
        color: percent >= 0 ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class MomentumBadge extends StatelessWidget {
  final MomentumLevel level;

  const MomentumBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class YearBreakdownRow extends StatelessWidget {
  final int year;
  final int count;
  final double ratio;
  final String valueLabel;
  final VoidCallback? onTap;

  const YearBreakdownRow({
    super.key,
    required this.year,
    required this.count,
    required this.ratio,
    this.valueLabel = 'publications',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$year',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    _formatCount(count),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    ' $valueLabel',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.05, 1.0),
                  minHeight: 3,
                  backgroundColor: AppColors.surfaceMuted,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

class TopicGrowthRow extends StatelessWidget {
  final String name;
  final double growthPercent;
  final VoidCallback? onTap;

  const TopicGrowthRow({
    super.key,
    required this.name,
    required this.growthPercent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GrowthLabel(percent: growthPercent),
          ],
        ),
      ),
    );
  }
}
