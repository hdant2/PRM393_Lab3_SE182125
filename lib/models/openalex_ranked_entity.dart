// =============================================================================
// openalex_ranked_entity.dart — MỘT HÀNG XẾP HẠNG TỪ group_by
// =============================================================================

/// Một hàng xếp hạng từ OpenAlex `group_by`.
///
/// Ví dụ group_by=authorships.author.id → name = tên tác giả, count = số bài
/// trong phạm vi filter/search hiện tại. id dùng cho API filter chi tiết.
class OpenAlexRankedEntity {
  final String id;
  final String name;
  final int count;

  const OpenAlexRankedEntity({
    required this.id,
    required this.name,
    required this.count,
  });

  /// Chuyển sang MapEntry cho bar chart widgets
  MapEntry<String, int> get entry => MapEntry(name, count);
}
