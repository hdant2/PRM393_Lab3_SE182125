/// Model đại diện cho một bài báo khoa học
class Publication {

  /// ID duy nhất của bài báo
  final String id;

  /// Tên bài báo
  final String title;

  /// Năm xuất bản
  final int year;

  /// Số lượt trích dẫn
  final int citations;

  /// Tên tạp chí
  final String journal;

  /// DOI của bài báo
  final String doi;

  /// Danh sách tác giả
  final List<String> authors;
  /// Tóm tắt bài báo
  final String abstractText;

  Publication({
    required this.id,
    required this.title,
    required this.year,
    required this.citations,
    required this.journal,
    required this.doi,
    required this.authors,
    required this.abstractText,
  });

  /// Chuyển JSON từ OpenAlex thành Publication object
  factory Publication.fromJson(Map<String, dynamic> json) {
       final abstract = _buildAbstract(
    json['abstract_inverted_index'],
  );

  // print("TITLE: ${json['title']}");
  // print("HAS ABSTRACT: ${json['abstract_inverted_index'] != null}");
  // print(
  //   "ABSTRACT PREVIEW: "
  //   "${abstract.length > 200 ? abstract.substring(0, 200) : abstract}",
  // );


    return Publication(

      // ID
      id: json['id'] ?? '',

      // Title
      title: json['title'] ?? 'No Title',

      // Publication Year
      year: json['publication_year'] ?? 0,

      // Citation Count
      citations: json['cited_by_count'] ?? 0,

      // Journal Name
      journal:
          json['primary_location']
                  ?['source']
                  ?['display_name']
              ?? 'Unknown Journal',

      // DOI
      doi: json['doi'] ?? '',

      // Authors
      // Authors
      authors: _buildAuthors(json['authorships']),
      // Abstract
      abstractText: _buildAbstract(
      json['abstract_inverted_index'],
    ),
    );
  }

  /// Convert OpenAlex authorships thành danh sách tên tác giả
  static List<String> _buildAuthors(List<dynamic>? authorships) {
    if (authorships == null) {
      return [];
    }

    return authorships
        .map(
          (item) =>
              item['author']?['display_name']?.toString() ??
              'Unknown Author',
        )
        .toList();
  }

  /// Convert OpenAlex abstract_inverted_index
/// thành đoạn abstract bình thường
static String _buildAbstract(
    Map<String, dynamic>? invertedIndex) {

  if (invertedIndex == null) {
    return 'No abstract available';
  }

  final Map<int, String> words = {};

  invertedIndex.forEach(
    (word, positions) {
      for (var pos in positions) {
        words[pos] = word;
      }
    },
  );

  final sortedKeys =
      words.keys.toList()..sort();

  final abstract = sortedKeys
      .map((key) => words[key])
      .join(' ');

  // Nếu quá ngắn hoặc không hợp lệ
  if (abstract.trim().isEmpty) {
    return 'No abstract available';
  }

  return abstract;
}
}