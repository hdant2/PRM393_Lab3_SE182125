// Footer phân trang — "Load more" khi search / detail list 20 bài/trang
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/count_format.dart';

/// Hiện loaded/total + nút Load more — gọi callback từ PublicationProvider
class LoadMoreFooter extends StatelessWidget {
  final int loadedCount;
  final int totalCount;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const LoadMoreFooter({
    super.key,
    required this.loadedCount,
    required this.totalCount,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 0 && !hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'Showing ${formatOpenAlexCount(loadedCount)} of '
            '${formatOpenAlexCount(totalCount)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (hasMore) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: isLoading ? null : onLoadMore,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more'),
            ),
          ],
        ],
      ),
    );
  }
}
