import 'publication_author.dart';

// =============================================================================
// publication.dart — MODEL MỘT BÀI BÁO (map từ JSON OpenAlex)
// =============================================================================
// OpenAlex trả abstract dạng "inverted index" (từ → vị trí) → _buildAbstract()
// ghép lại thành câu. Concepts lọc score >= 0.35, lấy top 3.
// readUrl: ưu tiên Open Access → PDF → landing page → DOI
// =============================================================================

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

  /// DOI của bài báo (URL đầy đủ từ OpenAlex)
  final String doi;

  /// Danh sách tác giả (id + tên)
  final List<PublicationAuthor> authorEntries;

  /// Tóm tắt bài báo
  final String abstractText;

  /// Lĩnh vực nghiên cứu (từ OpenAlex concepts)
  final List<String> concepts;

  /// Trang publisher / landing page
  final String? landingPageUrl;

  /// Link đọc miễn phí (OA) nếu OpenAlex có
  final String? openAccessUrl;

  /// PDF trực tiếp nếu OpenAlex có
  final String? pdfUrl;

  /// Loại publication (article, book…)
  final String workType;

  /// ID các bài liên quan từ OpenAlex `related_works`
  final List<String> relatedWorkIds;

  Publication({
    required this.id,
    required this.title,
    required this.year,
    required this.citations,
    required this.journal,
    required this.doi,
    required this.authorEntries,
    required this.abstractText,
    this.concepts = const [],
    this.landingPageUrl,
    this.openAccessUrl,
    this.pdfUrl,
    this.workType = 'Journal Article',
    this.relatedWorkIds = const [],
  });

  List<String> get authors =>
      authorEntries.map((author) => author.name).toList();

  /// URL trang OpenAlex của bài
  String get openAlexUrl => id;

  /// DOI rút gọn để hiển thị (bỏ prefix doi.org)
  String get displayDoi {
    if (doi.isEmpty) return '';
    return doi.replaceFirst(
      RegExp(r'^https?://(dx\.)?doi\.org/', caseSensitive: false),
      '',
    );
  }

  /// URL DOI đầy đủ để mở trình duyệt
  String? get doiUrl {
    if (doi.isEmpty) return null;
    if (doi.startsWith('http')) return doi;
    return 'https://doi.org/$doi';
  }

  bool get hasDoi => displayDoi.isNotEmpty;

  /// Link đọc bài — ưu tiên OA → PDF → publisher landing → DOI
  String? get readUrl {
    if (openAccessUrl != null && openAccessUrl!.isNotEmpty) {
      return openAccessUrl;
    }
    if (pdfUrl != null && pdfUrl!.isNotEmpty) return pdfUrl;
    if (landingPageUrl != null && landingPageUrl!.isNotEmpty) {
      return landingPageUrl;
    }
    return doiUrl;
  }

  bool get hasReadLink => readUrl != null;

  /// Chuyển 1 phần tử trong results[] của GET /works thành Publication
  factory Publication.fromJson(Map<String, dynamic> json) {
    final urls = _parseUrls(json);

    return Publication(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      year: json['publication_year'] ?? 0,
      citations: json['cited_by_count'] ?? 0,
      journal: json['primary_location']?['source']?['display_name'] ??
          'Unknown Journal',
      doi: json['doi']?.toString() ?? '',
      authorEntries: _buildAuthorEntries(json['authorships']),
      abstractText: _buildAbstract(json['abstract_inverted_index']),
      concepts: _buildConcepts(json['concepts']),
      landingPageUrl: urls.landingPageUrl,
      openAccessUrl: urls.openAccessUrl,
      pdfUrl: urls.pdfUrl,
      workType: _humanizeType(json['type']?.toString()),
      relatedWorkIds: _buildRelatedIds(json['related_works']),
    );
  }

  static ({String? landingPageUrl, String? openAccessUrl, String? pdfUrl})
      _parseUrls(Map<String, dynamic> json) {
    final primary = json['primary_location'] as Map<String, dynamic>?;
    final bestOa = json['best_oa_location'] as Map<String, dynamic>?;
    final openAccess = json['open_access'] as Map<String, dynamic>?;

    final landingPageUrl = primary?['landing_page_url']?.toString();
    final openAccessUrl = bestOa?['landing_page_url']?.toString() ??
        openAccess?['oa_url']?.toString();
    final pdfUrl = bestOa?['pdf_url']?.toString() ??
        primary?['pdf_url']?.toString();

    return (
      landingPageUrl:
          landingPageUrl != null && landingPageUrl.isNotEmpty
              ? landingPageUrl
              : null,
      openAccessUrl:
          openAccessUrl != null && openAccessUrl.isNotEmpty
              ? openAccessUrl
              : null,
      pdfUrl: pdfUrl != null && pdfUrl.isNotEmpty ? pdfUrl : null,
    );
  }

  static String _humanizeType(String? type) {
    if (type == null || type.isEmpty) return 'Journal Article';
    return type
        .split('-')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  static List<String> _buildRelatedIds(List<dynamic>? relatedWorks) {
    if (relatedWorks == null) return [];
    return relatedWorks
        .map((item) => item.toString())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  static List<String> _buildConcepts(List<dynamic>? concepts) {
    if (concepts == null) return [];

    final scored = <MapEntry<String, double>>[];
    for (final item in concepts) {
      final name = item['display_name']?.toString();
      final score = (item['score'] as num?)?.toDouble() ?? 0;
      if (name == null || name.isEmpty || score < 0.35) continue;
      scored.add(MapEntry(name, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(3).map((e) => e.key).toList();
  }

  static List<PublicationAuthor> _buildAuthorEntries(
    List<dynamic>? authorships,
  ) {
    if (authorships == null) return [];

    return authorships
        .map((item) {
          final author = item['author'] as Map<String, dynamic>?;
          return PublicationAuthor(
            id: author?['id']?.toString() ?? '',
            name: author?['display_name']?.toString() ?? 'Unknown Author',
          );
        })
        .where((author) => author.name.isNotEmpty)
        .toList();
  }

  /// OpenAlex lưu abstract dạng { "word": [0, 5, 12], ... } — ghép theo index
  static String _buildAbstract(Map<String, dynamic>? invertedIndex) {
    if (invertedIndex == null) {
      return 'No abstract available';
    }

    final Map<int, String> words = {};

    invertedIndex.forEach((word, positions) {
      for (var pos in positions) {
        words[pos] = word;
      }
    });

    final sortedKeys = words.keys.toList()..sort();

    final abstract = sortedKeys.map((key) => words[key]).join(' ');

    if (abstract.trim().isEmpty) {
      return 'No abstract available';
    }

    return abstract;
  }
}
