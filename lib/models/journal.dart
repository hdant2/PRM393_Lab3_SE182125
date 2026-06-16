import 'publication.dart';

class Journal {
  final String name;
  final List<Publication> publications;

  Journal({
    required this.name,
    required this.publications,
  });

  int get totalPapers => publications.length;
}