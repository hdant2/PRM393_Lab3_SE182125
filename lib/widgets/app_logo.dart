// =============================================================================
// app_logo.dart — LOGO + UI COMPONENTS DÙNG CHUNG
// =============================================================================
// AppLogo, JournalAiAppBar, MockupCard, GrowthBadge, LandscapeTile, StatColumn
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    // assets/images/app_logo.png — fallback emoji nếu thiếu file
    return ClipOval(
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text('🦝', style: TextStyle(fontSize: size * 0.5)),
        ),
      ),
    );
  }
}

/// Header Overview/About — logo + refresh (gọi provider.refreshCurrentAnalysis)
class JournalAiAppBar extends StatelessWidget {
  final bool showRefresh;
  final bool showBell;

  const JournalAiAppBar({
    super.key,
    this.showRefresh = false,
    this.showBell = true,
  });

  @override
  Widget build(BuildContext context) {
    final provider = showRefresh ? context.watch<PublicationProvider>() : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          const AppLogo(size: 34),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JournalAI',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Research Intelligence',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (showRefresh && provider != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: provider.isLoading
                  ? null
                  : () => provider.loadDefaultDashboard(),
            )
          else if (showBell)
            IconButton(
              icon: const Icon(Icons.notifications_none, size: 22),
              onPressed: () {},
            ),
        ],
      ),
    );
  }
}

/// Container trắng viền bo — card style chính của app
class MockupCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const MockupCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Badge YoY trên Overview pulse card
class GrowthBadge extends StatelessWidget {
  final double percent;

  const GrowthBadge({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final sign = percent >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$sign${percent.toStringAsFixed(1)}% YoY Growth',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tile menu có icon — Research Landscape, Keywords hub, Home links
class LandscapeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const LandscapeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppColors.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cột stat 3 ô trên Overview (Average Citations, Peak Year…)
class StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;

  const StatColumn({
    super.key,
    required this.label,
    required this.value,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (hint != null && hint!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
