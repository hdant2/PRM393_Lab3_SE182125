// Model legacy — gom publications theo tên tác giả (dùng trong test / analytics local)
import 'publication.dart';

/// Tác giả + danh sách bài (tính local, không từ OpenAlex group_by)
class Author {
  final String name;
  final List<Publication> publications;

  Author({
    required this.name,
    required this.publications,
  });

  int get totalPapers => publications.length;
}
