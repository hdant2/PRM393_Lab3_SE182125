// =============================================================================
// publication_analytics.dart — PHÂN TÍCH LOCAL (KHÔNG GỌI API)
// =============================================================================
// Tính trend/top author/journal từ List<Publication> đã có sẵn.
// UI chính dùng OpenAlex group_by; class này phục vụ unit test & fallback logic.
// =============================================================================

import '../models/publication.dart';

class PublicationAnalytics {
  /// Trung bình cited_by_count trong list
  static double averageCitation(List<Publication> publications) {
    if (publications.isEmpty) return 0;
    final total = publications.fold(0, (sum, p) => sum + p.citations);
    return total / publications.length;
  }

  /// Năm có nhiều bài nhất
  static String mostActiveYear(List<Publication> publications) {
    final yearCount = groupByYear(publications);
    if (yearCount.isEmpty) return 'N/A';
    return '${yearCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key}';
  }

  /// Map năm → số bài
  static Map<int, int> groupByYear(List<Publication> publications) {
    final yearlyData = <int, int>{};
    for (final p in publications) {
      if (p.year == 0) continue;
      yearlyData[p.year] = (yearlyData[p.year] ?? 0) + 1;
    }
    return yearlyData;
  }

  /// Map năm → tổng citations
  static Map<int, int> citationsByYear(List<Publication> publications) {
    final yearlyData = <int, int>{};
    for (final p in publications) {
      if (p.year == 0) continue;
      yearlyData[p.year] = (yearlyData[p.year] ?? 0) + p.citations;
    }
    return yearlyData;
  }

  /// Map năm → citations trung bình mỗi bài
  static Map<int, int> averageCitationsByYear(List<Publication> publications) {
    final totals = <int, int>{};
    final counts = <int, int>{};
    for (final p in publications) {
      if (p.year == 0) continue;
      totals[p.year] = (totals[p.year] ?? 0) + p.citations;
      counts[p.year] = (counts[p.year] ?? 0) + 1;
    }
    return {
      for (final year in totals.keys)
        year: (totals[year]! / counts[year]!).round(),
    };
  }

  /// Lọc bài theo năm, sort citations desc
  static List<Publication> papersForYear(
    List<Publication> publications,
    int year,
  ) {
    return publications.where((p) => p.year == year).toList()
      ..sort((a, b) => b.citations.compareTo(a.citations));
  }

  static List<MapEntry<String, int>> topResearchAreasForYear(
    List<Publication> publications,
    int year, {
    int limit = 5,
  }) {
    return topResearchAreas(papersForYear(publications, year), limit: limit);
  }

  static List<MapEntry<String, int>> topJournals(
    List<Publication> publications, {
    int limit = 5,
  }) {
    final journalCount = <String, int>{};
    for (final p in publications) {
      if (p.journal == 'Unknown Journal') continue;
      journalCount[p.journal] = (journalCount[p.journal] ?? 0) + 1;
    }
    final sorted = journalCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  static List<MapEntry<String, int>> topAuthors(
    List<Publication> publications, {
    int limit = 10,
  }) {
    final authorCount = <String, int>{};
    for (final p in publications) {
      for (final author in p.authors) {
        if (author == 'Unknown Author') continue;
        authorCount[author] = (authorCount[author] ?? 0) + 1;
      }
    }
    final sorted = authorCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  static List<Publication> topPapers(
    List<Publication> publications, {
    int limit = 10,
  }) {
    final uniquePapers = <String, Publication>{};
    for (final paper in publications) {
      uniquePapers[paper.id] = paper;
    }
    final sorted = uniquePapers.values.toList()
      ..sort((a, b) => b.citations.compareTo(a.citations));
    return sorted.take(limit).toList();
  }

  static Publication mostInfluentialPaper(List<Publication> publications) {
    return publications.reduce((a, b) => a.citations >= b.citations ? a : b);
  }

  static List<MapEntry<String, int>> topResearchAreas(
    List<Publication> publications, {
    int limit = 5,
  }) {
    final areaCount = <String, int>{};
    for (final p in publications) {
      for (final area in p.concepts) {
        areaCount[area] = (areaCount[area] ?? 0) + 1;
      }
    }
    final sorted = areaCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }
}
