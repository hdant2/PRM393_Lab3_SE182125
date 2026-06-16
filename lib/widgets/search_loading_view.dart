import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// =============================================================================
// search_loading_view.dart — LOADING KHI SEARCH (Explore)
// =============================================================================
// Raccoon illustration + progress bar — chỉ hiện khi chưa có bài nào.
// =============================================================================

/// Màn loading khi đang tìm kiếm topic trên Explore.
class SearchLoadingView extends StatelessWidget {
  final String query;

  const SearchLoadingView({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/search_loading.png',
                width: 280,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 280,
                  height: 280,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text('🦝', style: TextStyle(fontSize: 64)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              query.isEmpty ? 'Searching…' : 'Searching “$query”',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fetching publications from OpenAlex',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppColors.surfaceMuted,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
