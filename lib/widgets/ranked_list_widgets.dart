import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tiêu đề section kèm mô tả ngắn (dùng chung các màn detail).
class ScreenSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ScreenSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Hàng xếp hạng có nhãn metric rõ ràng (publications, citations…).
class RankedMetricTile extends StatelessWidget {
  final int rank;
  final String title;
  final String? subtitle;
  final String metricValue;
  final String metricLabel;
  final VoidCallback? onTap;

  const RankedMetricTile({
    super.key,
    required this.rank,
    required this.title,
    this.subtitle,
    required this.metricValue,
    required this.metricLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  metricValue,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  metricLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
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
      ),
    );
  }
}

/// Header cột cho bảng xếp hạng.
class RankedListHeader extends StatelessWidget {
  final String metricColumnLabel;

  const RankedListHeader({super.key, required this.metricColumnLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            child: Text('#', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
          const Expanded(
            child: Text(
              'Name',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          Text(
            metricColumnLabel,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
