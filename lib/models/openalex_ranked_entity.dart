/// Một hàng xếp hạng từ OpenAlex `group_by` (author, journal, concept…)
class OpenAlexRankedEntity {
  final String id;
  final String name;
  final int count;

  const OpenAlexRankedEntity({
    required this.id,
    required this.name,
    required this.count,
  });

  MapEntry<String, int> get entry => MapEntry(name, count);
}
