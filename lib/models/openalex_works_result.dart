import '../models/publication.dart';

class OpenAlexWorksResult {
  final List<Publication> publications;
  final int totalOnOpenAlex;

  const OpenAlexWorksResult({
    required this.publications,
    required this.totalOnOpenAlex,
  });

  bool hasMore(int loadedCount) => loadedCount < totalOnOpenAlex;
}
