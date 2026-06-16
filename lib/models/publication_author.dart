/// Tác giả bài báo (id + tên từ OpenAlex authorships)
class PublicationAuthor {
  final String id;
  final String name;

  const PublicationAuthor({
    required this.id,
    required this.name,
  });

  bool get hasOpenAlexId => id.isNotEmpty;
}
