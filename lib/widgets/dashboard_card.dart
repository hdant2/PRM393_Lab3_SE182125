import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  // =====================================================
  // CARD DATA
  // =====================================================

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // =====================================================
      // CLICK EVENT
      // =====================================================
      onTap: onTap,

      borderRadius: BorderRadius.circular(16),

      child: Card(
        elevation: 4,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              // =====================================================
              // ICON
              // =====================================================
              Icon(icon, color: color, size: 38),

              const SizedBox(height: 10),

              // =====================================================
              // TITLE
              // =====================================================
              Text(
                title,

                textAlign: TextAlign.center,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              // =====================================================
              // VALUE
              // =====================================================
              Text(
                value,

                textAlign: TextAlign.center,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
