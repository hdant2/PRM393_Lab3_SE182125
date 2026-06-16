// =============================================================================
// openalex_works_result.dart — KẾT QUẢ PHÂN TRANG /works
// =============================================================================

import '../models/publication.dart';

/// Kết quả một trang GET /works từ OpenAlex.
///
/// [publications] — tối đa 20 bài (listPageSize)
/// [totalOnOpenAlex] — meta.count (ví dụ ~201700 khi search "ras")
/// [hasMore] — còn trang để Load more không
class OpenAlexWorksResult {
  final List<Publication> publications;
  final int totalOnOpenAlex;

  const OpenAlexWorksResult({
    required this.publications,
    required this.totalOnOpenAlex,
  });

  bool hasMore(int loadedCount) => loadedCount < totalOnOpenAlex;
}
