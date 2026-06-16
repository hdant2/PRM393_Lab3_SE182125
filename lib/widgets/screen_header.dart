import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;

  const ScreenHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          leading ??
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {},
              ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}
