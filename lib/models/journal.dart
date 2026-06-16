// Model legacy — gom publications theo tên journal (test / analytics local)
import 'publication.dart';

/// Journal + danh sách bài (tính local từ list Publication)
class Journal {
  final String name;
  final List<Publication> publications;

  Journal({
    required this.name,
    required this.publications,
  });

  int get totalPapers => publications.length;
}
