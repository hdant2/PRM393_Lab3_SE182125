import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Banner cố định phía trên chart — không bị ngón tay che khi chạm.
class ChartTouchBanner extends StatelessWidget {
  final String? primaryText;
  final String? secondaryText;

  const ChartTouchBanner({
    super.key,
    this.primaryText,
    this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    final hint = primaryText == null && secondaryText != null;

    return Container(
      width: double.infinity,
      height: 36,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: hint
            ? AppColors.border.withValues(alpha: 0.35)
            : AppColors.chartPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hint
              ? AppColors.border
              : AppColors.chartPrimary.withValues(alpha: 0.25),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: hint
          ? Text(
              secondaryText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            )
          : RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                children: [
                  TextSpan(
                    text: primaryText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (secondaryText != null)
                    TextSpan(
                      text: ' · $secondaryText',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
