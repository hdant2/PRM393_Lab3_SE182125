// =============================================================================
// openalex_impact_profile.dart — TÁC GIẢ / TỔ CHỨC VỚI IMPACT METRICS
// =============================================================================

/// Hồ sơ impact từ `/authors` hoặc `/institutions` (career stats OpenAlex).
class OpenAlexImpactProfile {
  final String id;
  final String name;
  final int worksCount;
  final int citedByCount;
  final int hIndex;

  const OpenAlexImpactProfile({
    required this.id,
    required this.name,
    required this.worksCount,
    required this.citedByCount,
    this.hIndex = 0,
  });
}
