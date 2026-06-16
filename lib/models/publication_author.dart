// =============================================================================
// publication_author.dart — TÁC GIẢ TRONG MỘT BÀI BÁO
// =============================================================================
// OpenAlex trả authorships[].author → map thành id + display_name.
// id dùng filter API khi mở AuthorDetailScreen.
// =============================================================================

/// Tác giả bài báo (id + tên từ OpenAlex authorships)
class PublicationAuthor {
  /// OpenAlex author id, ví dụ https://openalex.org/A123
  final String id;

  /// Tên hiển thị
  final String name;

  const PublicationAuthor({
    required this.id,
    required this.name,
  });

  /// Có id thật từ OpenAlex (tap được sang màn detail)
  bool get hasOpenAlexId => id.isNotEmpty;
}
