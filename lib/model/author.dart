import 'publication.dart';

class Author {
  final String name;
  final List<Publication> publications;

  Author({
    required this.name,
    required this.publications,
  });

  int get totalPapers => publications.length;
}