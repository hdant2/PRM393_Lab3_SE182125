import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/openalex_impact_profile.dart';
import '../models/openalex_ranked_entity.dart';
import '../models/openalex_works_result.dart';
import '../models/publication.dart';
import '../models/research_insight.dart';
import '../utils/analytics_year.dart';
import '../utils/research_insights.dart';
import 'openalex_config.dart';
import 'openalex_exception.dart';

// =============================================================================
// openalex_service.dart — TẦNG API (gọi OpenAlex)
// =============================================================================
// Mọi HTTP tới https://api.openalex.org/works đi qua file này.
//
// Endpoint chính: GET /works với các tham số:
//   search=ras          → full-text search (giống web OpenAlex)
//   filter=...          → lọc theo năm, author, journal, concept…
//   group_by=...        → aggregate (top author, trend theo năm…)
//   sort=...            → chỉ dùng khi cần xếp theo citations
//   per-page, page      → phân trang (app dùng 20 bài/trang)
//
// Luồng điển hình:
//   SearchScreen → PublicationProvider.searchPublications()
//                → fetchSearchPage() → _fetchWorksPage()
//                → Publication.fromJson() cho từng item trong results[]
// =============================================================================

/// Service chịu trách nhiệm giao tiếp với OpenAlex API
class OpenAlexService {
  OpenAlexService(
    this._config, {
    http.Client? httpClient,
    int? maxRetries,
    Duration? requestTimeout,
    int? retryBackoffMs,
  })  : _httpClient = httpClient ?? http.Client(),
        _maxRetries = maxRetries ?? 4,
        _requestTimeout = requestTimeout ?? const Duration(seconds: 45),
        _retryBackoffMs = retryBackoffMs ?? 1500;

  final OpenAlexConfig _config;
  final http.Client _httpClient;
  final int _maxRetries;
  final Duration _requestTimeout;
  final int _retryBackoffMs;

  String get _apiKey => _config.apiKey;

  static const Set<int> _retryStatusCodes = {429, 502, 503, 504};
  static const String _sortByCitationsDesc = 'cited_by_count:desc';
  static const String _apiHost = 'api.openalex.org';
  static const String _mailto = 'prm393.lab2@example.com';

  /// OpenAlex cho tối đa 100 bài/request; app hiển thị 20/trang cho UX
  static const int _perPage = 100;
  static const int listPageSize = 20;
  static const int _searchListPages = 3;
  static const int _citationScanPerPage = 200;
  static const int _citationScanMaxPages = 15;

  /// Tên field group_by — dùng cho top authors / journals / research domains
  static const String groupByAuthor = 'authorships.author.id';
  static const String groupByJournal = 'primary_location.source.id';
  static const String groupByTopic = 'topics.id';
  /// Alias cũ — OpenAlex web dùng Topics, không còn Concepts.
  static const String groupByConcept = groupByTopic;
  static const String groupByInstitution = 'authorships.institutions.id';
  static const String groupByType = 'type';
  static const String groupByOpenAccess = 'open_access.is_oa';
  static const String groupByCountry = 'authorships.countries';

  static const String _sortByHIndexDesc = 'summary_stats.h_index:desc';

  static const String _selectFields =
      'id,title,publication_year,cited_by_count,type,authorships,'
      'primary_location,best_oa_location,open_access,abstract_inverted_index,'
      'doi,concepts,related_works';

  String get _trendYearFilter {
    final endYear = DateTime.now().year;
    return 'publication_year:$kAnalyticsStartYear-$endYear';
  }

  List<int> get _trendYears {
    final endYear = DateTime.now().year;
    return [
      for (var year = kAnalyticsStartYear; year <= endYear; year++) year,
    ];
  }

  /// Search trang 1 — wrapper cho provider
  Future<OpenAlexWorksResult> searchPublications(String topic) {
    return fetchSearchPage(topic, page: 1);
  }

  /// Danh sách bài khi user search (Explore tab).
  /// KHÔNG sort theo citations → OpenAlex xếp theo relevance (giống web).
  Future<OpenAlexWorksResult> fetchSearchPage(
    String topic, {
    required int page,
    int perPage = listPageSize,
  }) {
    return _fetchWorksResultPage(
      _searchListParams(topic),
      page: page,
      perPage: perPage,
    );
  }

  /// meta.count — tổng số bài khớp filter/search (per-page=1 cho nhẹ).
  Future<int> fetchWorksTotalCount({
    String? search,
    bool globalInfluential = false,
  }) async {
    final page = await _fetchWorksPage(
      _listBaseParams(
        search: search,
        globalInfluential: globalInfluential,
      ),
      page: 1,
      perPage: 1,
    );
    return page.totalOnOpenAlex;
  }

  /// Top bài trích dẫn cao (Citation Leaders) — luôn sort citations desc
  Future<List<Publication>> fetchTopPapers({
    String? search,
    bool globalInfluential = false,
    int limit = 10,
  }) async {
    final page = await _fetchWorksPage(
      _topPapersParams(
        search: search,
        globalInfluential: globalInfluential,
      ),
      page: 1,
      perPage: limit.clamp(1, _perPage),
    );
    return page.publications;
  }

  /// Trung bình cited_by_count — lấy mẫu 100 bài đầu.
  Future<double> fetchAverageCitation({
    String? search,
    bool globalInfluential = false,
  }) async {
    final page = await _fetchWorksPage(
      {
        ..._listBaseParams(
          search: search,
          globalInfluential: globalInfluential,
        ),
        'select': 'cited_by_count',
      },
      page: 1,
      perPage: _perPage,
    );

    if (page.publications.isEmpty) return 0;

    final total = page.publications.fold<int>(
      0,
      (sum, paper) => sum + paper.citations,
    );
    return total / page.publications.length;
  }

  Future<Map<int, int>> fetchPublicationTrendByYear({
    String? search,
    bool globalInfluential = false,
  }) async {
    // GET /works?group_by=publication_year → biểu đồ trend
    final data = await _fetchWorksGroupBy(
      groupBy: 'publication_year',
      search: search,
      globalInfluential: globalInfluential,
    );
    return parseGroupByYear(data);
  }

  /// Tổng + trung bình citations theo từng năm.
  /// Dùng volume chính xác từ group_by, paginate cited_by_count, ước lượng khi quá lớn.
  Future<({Map<int, int> totals, Map<int, int> averages})>
      fetchCitationMetricsByYear({
    String? search,
    bool globalInfluential = false,
  }) async {
    final volumeByYear = await fetchPublicationTrendByYear(
      search: search,
      globalInfluential: globalInfluential,
    );

    final totals = <int, int>{};
    final averages = <int, int>{};

    final yearsToScan = _yearsForCitationScan(
      volumeByYear: volumeByYear,
      search: search,
    );
    if (yearsToScan.isEmpty) {
      return (totals: totals, averages: averages);
    }

    final yearMetrics = await Future.wait(
      yearsToScan.map((year) async {
        final expectedVolume = volumeByYear[year] ?? 0;
        if (expectedVolume <= 0) return (year: year, sum: 0, average: 0);

        final scanned = await _scanYearCitationTotals(
          year: year,
          expectedVolume: expectedVolume,
          search: search,
          globalInfluential: globalInfluential,
        );
        return (year: year, sum: scanned.sum, average: scanned.average);
      }),
    );

    for (final metric in yearMetrics) {
      if (metric.sum <= 0) continue;
      totals[metric.year] = metric.sum;
      averages[metric.year] = metric.average;
    }

    return (totals: totals, averages: averages);
  }

  List<int> _yearsForCitationScan({
    required Map<int, int> volumeByYear,
    String? search,
  }) {
    if (search == null || search.trim().isEmpty) return _trendYears;

    final years = volumeByYear.entries
        .where((entry) => entry.value > 0 && entry.key >= kAnalyticsStartYear)
        .map((entry) => entry.key)
        .toList()
      ..sort();
    if (years.length <= 20) return years;
    return years.sublist(years.length - 20);
  }

  /// Paginate cited_by_count for one year; extrapolate when sample < volume.
  Future<({int sum, int average})> _scanYearCitationTotals({
    required int year,
    required int expectedVolume,
    String? search,
    bool globalInfluential = false,
  }) async {
    final params = _citationYearScanParams(
      year: year,
      search: search,
      globalInfluential: globalInfluential,
    );

    var sum = 0;
    var scanned = 0;
    final pagesNeeded =
        ((expectedVolume + _citationScanPerPage - 1) ~/ _citationScanPerPage)
            .clamp(1, _citationScanMaxPages);

    for (var page = 1; page <= pagesNeeded; page++) {
      final result = await _fetchWorksPage(
        params,
        page: page,
        perPage: _citationScanPerPage,
      );

      if (result.publications.isEmpty) break;

      for (final paper in result.publications) {
        sum += paper.citations;
        scanned++;
      }

      if (result.publications.length < _citationScanPerPage) break;
      if (scanned >= expectedVolume) break;
    }

    if (scanned == 0) return (sum: 0, average: 0);

    if (scanned < expectedVolume) {
      final avg = sum / scanned;
      return (
        sum: (avg * expectedVolume).round(),
        average: avg.round(),
      );
    }

    return (
      sum: sum,
      average: (sum / scanned).round(),
    );
  }

  Map<String, String> _citationYearScanParams({
    required int year,
    String? search,
    bool globalInfluential = false,
  }) {
    return {
      'filter': _yearFilter(
        year: year,
        search: search,
        globalInfluential: globalInfluential,
      ),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'select': 'cited_by_count',
    };
  }

  /// group_by bất kỳ (author, journal, concept…) → ranked list.
  Future<List<OpenAlexRankedEntity>> fetchWorksGroupedCounts({
    required String groupBy,
    String? search,
    bool globalInfluential = false,
    int limit = 10,
    String? filterOverride,
  }) async {
    final data = await _fetchWorksGroupBy(
      groupBy: groupBy,
      search: search,
      globalInfluential: globalInfluential,
      filterOverride: filterOverride,
    );
    return parseGroupByNamedCounts(data, limit: limit);
  }

  /// Top authors theo tổng trích dẫn (career) — `GET /authors`.
  Future<List<OpenAlexRankedEntity>> fetchTopAuthorsByCitations({
    String? search,
    bool globalInfluential = false,
    List<String>? topicIds,
    int limit = 10,
  }) async {
    if (topicIds != null && topicIds.isNotEmpty) {
      final profiles = await _fetchEntityImpactProfiles(
        entityPath: 'authors',
        sort: _sortByCitationsDesc,
        topicIds: topicIds,
        limit: limit,
      );
      return _profilesToRankedByCitations(profiles);
    }

    if (search != null && search.trim().isNotEmpty) {
      return fetchTopAuthorsByCitationsFromWorks(
        search: search,
        limit: limit,
      );
    }

    final profiles = await _fetchEntityImpactProfiles(
      entityPath: 'authors',
      sort: _sortByCitationsDesc,
      globalInfluential: globalInfluential,
      limit: limit,
    );
    return _profilesToRankedByCitations(profiles);
  }

  /// Top institutions theo tổng trích dẫn — `GET /institutions`.
  Future<List<OpenAlexRankedEntity>> fetchTopInstitutionsByCitations({
    String? search,
    bool globalInfluential = false,
    List<String>? topicIds,
    int limit = 10,
  }) async {
    if (topicIds != null && topicIds.isNotEmpty) {
      final profiles = await _fetchEntityImpactProfiles(
        entityPath: 'institutions',
        sort: _sortByCitationsDesc,
        topicIds: topicIds,
        limit: limit,
      );
      return _profilesToRankedByCitations(profiles);
    }

    if (search != null && search.trim().isNotEmpty) {
      return const [];
    }

    final profiles = await _fetchEntityImpactProfiles(
      entityPath: 'institutions',
      sort: _sortByCitationsDesc,
      globalInfluential: globalInfluential,
      limit: limit,
    );
    return _profilesToRankedByCitations(profiles);
  }

  /// Top authors theo h-index (career stats OpenAlex).
  Future<List<OpenAlexRankedEntity>> fetchTopAuthorsByHIndex({
    String? search,
    bool globalInfluential = false,
    List<String>? topicIds,
    int limit = 10,
  }) async {
    if ((topicIds == null || topicIds.isEmpty) &&
        search != null &&
        search.trim().isNotEmpty) {
      return const [];
    }

    final profiles = await _fetchEntityImpactProfiles(
      entityPath: 'authors',
      sort: _sortByHIndexDesc,
      globalInfluential: globalInfluential,
      topicIds: topicIds,
      limit: limit,
    );
    return profiles
        .where((profile) => profile.hIndex > 0)
        .map(
          (profile) => OpenAlexRankedEntity(
            id: profile.id,
            name: profile.name,
            count: profile.hIndex,
          ),
        )
        .toList();
  }

  /// Scatter productivity (works) vs impact (citations) — cùng nguồn `/authors`.
  Future<List<OpenAlexImpactProfile>> fetchAuthorImpactProfiles({
    String? search,
    bool globalInfluential = false,
    List<String>? topicIds,
    int limit = 12,
  }) async {
    if (topicIds != null && topicIds.isNotEmpty) {
      return _fetchEntityImpactProfiles(
        entityPath: 'authors',
        sort: _sortByCitationsDesc,
        topicIds: topicIds,
        limit: limit,
      );
    }

    if (search != null && search.trim().isNotEmpty) {
      return _authorImpactProfilesFromWorks(search: search, limit: limit);
    }

    return _fetchEntityImpactProfiles(
      entityPath: 'authors',
      sort: _sortByCitationsDesc,
      globalInfluential: globalInfluential,
      limit: limit,
    );
  }

  /// Topic search: gom citations theo tác giả từ các bài cited cao trong scope.
  Future<List<OpenAlexRankedEntity>> fetchTopAuthorsByCitationsFromWorks({
    required String search,
    int limit = 10,
  }) async {
    final profiles = await _authorImpactProfilesFromWorks(
      search: search,
      limit: limit,
    );
    return profiles
        .map(
          (profile) => OpenAlexRankedEntity(
            id: profile.id,
            name: profile.name,
            count: profile.citedByCount,
          ),
        )
        .toList();
  }

  Future<List<OpenAlexImpactProfile>> _authorImpactProfilesFromWorks({
    required String search,
    int limit = 12,
  }) async {
    final page = await _fetchWorksPage(
      {
        'search': search.trim(),
        'sort': _sortByCitationsDesc,
        'filter': _trendYearFilter,
        'select': 'cited_by_count,authorships',
      },
      page: 1,
      perPage: _perPage,
    );

    final totals = <String, ({String name, int citations, int papers})>{};
    for (final paper in page.publications) {
      for (final author in paper.authorEntries) {
        if (!author.hasOpenAlexId) continue;
        final current = totals[author.id];
        totals[author.id] = (
          name: author.name,
          citations: (current?.citations ?? 0) + paper.citations,
          papers: (current?.papers ?? 0) + 1,
        );
      }
    }

    final profiles = totals.entries
        .map(
          (entry) => OpenAlexImpactProfile(
            id: entry.key,
            name: entry.value.name,
            worksCount: entry.value.papers,
            citedByCount: entry.value.citations,
          ),
        )
        .toList()
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));

    if (profiles.length <= limit) return profiles;
    return profiles.sublist(0, limit);
  }

  /// Phân bố theo quốc gia trong phạm vi works hiện tại.
  Future<List<OpenAlexRankedEntity>> fetchCountryDistribution({
    String? search,
    bool globalInfluential = false,
    int limit = 10,
  }) {
    return fetchWorksGroupedCounts(
      groupBy: groupByCountry,
      search: search,
      globalInfluential: globalInfluential,
      limit: limit,
    );
  }

  /// Open access vs closed — đếm qua filter (chính xác hơn group_by boolean).
  Future<({int openCount, int closedCount})> fetchOpenAccessBreakdown({
    String? search,
    bool globalInfluential = false,
  }) async {
    final openCount = await _fetchScopedTotalCount(
      search: search,
      globalInfluential: globalInfluential,
      additionalFilter: 'open_access.is_oa:true',
    );
    final closedCount = await _fetchScopedTotalCount(
      search: search,
      globalInfluential: globalInfluential,
      additionalFilter: 'open_access.is_oa:false',
    );
    return (openCount: openCount, closedCount: closedCount);
  }

  /// Volume theo tháng trong một năm — OpenAlex không group_by month.
  Future<Map<int, int>> fetchPublicationTrendByMonth({
    required int year,
    String? search,
    bool globalInfluential = false,
  }) async {
    final now = DateTime.now();
    final lastMonth = year == now.year ? now.month : 12;
    if (lastMonth <= 0) return {};

    final entries = await Future.wait(
      List.generate(lastMonth, (index) async {
        final month = index + 1;
        final count = await _fetchMonthVolume(
          year: year,
          month: month,
          search: search,
          globalInfluential: globalInfluential,
        );
        return MapEntry(month, count);
      }),
    );

    return Map.fromEntries(entries);
  }

  Future<int> _fetchMonthVolume({
    required int year,
    required int month,
    String? search,
    bool globalInfluential = false,
  }) async {
    final page = await _fetchWorksPage(
      _monthCountParams(
        year: year,
        month: month,
        search: search,
        globalInfluential: globalInfluential,
      ),
      page: 1,
      perPage: 1,
    );
    return page.totalOnOpenAlex;
  }

  Map<String, String> _monthCountParams({
    required int year,
    required int month,
    String? search,
    bool globalInfluential = false,
  }) {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0);
    var filter =
        'from_publication_date:${_isoDate(from)},to_publication_date:${_isoDate(to)},publication_year:$year';
    if (globalInfluential && (search == null || search.trim().isEmpty)) {
      filter = '$filter,cited_by_count:>100';
    }

    final params = <String, String>{'filter': filter};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    return params;
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<int> _fetchScopedTotalCount({
    String? search,
    bool globalInfluential = false,
    String? additionalFilter,
  }) async {
    final params = _scopedCountParams(
      search: search,
      globalInfluential: globalInfluential,
      additionalFilter: additionalFilter,
    );
    final page = await _fetchWorksPage(params, page: 1, perPage: 1);
    return page.totalOnOpenAlex;
  }

  Map<String, String> _scopedCountParams({
    String? search,
    bool globalInfluential = false,
    String? additionalFilter,
  }) {
    final params = Map<String, String>.from(
      _listBaseParams(
        search: search,
        globalInfluential: globalInfluential,
      ),
    );

    if (additionalFilter == null || additionalFilter.isEmpty) {
      return params;
    }

    final existing = params['filter'];
    if (existing != null && existing.isNotEmpty) {
      params['filter'] = '$existing,$additionalFilter';
    } else {
      params['filter'] = additionalFilter;
    }

    return params;
  }

  /// Hot topics của một năm — group_by concept + filter publication_year.
  Future<List<OpenAlexRankedEntity>> fetchConceptsForYear({
    required int year,
    String? search,
    bool globalInfluential = false,
    int limit = 5,
  }) async {
    return fetchWorksGroupedCounts(
      groupBy: groupByConcept,
      search: search,
      globalInfluential: globalInfluential,
      limit: limit,
      filterOverride: _yearFilter(
        year: year,
        search: search,
        globalInfluential: globalInfluential,
      ),
    );
  }

  /// Bài theo năm — phân trang 20, sort citations.
  Future<OpenAlexWorksResult> fetchPublicationsForYearPage({
    required int year,
    required int page,
    String? search,
    bool globalInfluential = false,
    int perPage = listPageSize,
  }) {
    return _fetchWorksResultPage(
      _yearListParams(
        year: year,
        search: search,
        globalInfluential: globalInfluential,
      ),
      page: page,
      perPage: perPage,
    );
  }

  /// Wrapper lấy trang 1 bài theo năm.
  Future<List<Publication>> fetchPublicationsForYear({
    required int year,
    String? search,
    bool globalInfluential = false,
  }) async {
    final result = await fetchPublicationsForYearPage(
      year: year,
      page: 1,
      search: search,
      globalInfluential: globalInfluential,
    );
    return result.publications;
  }

  /// Bài của 1 author — filter authorships.author.id, paginated.
  Future<OpenAlexWorksResult> fetchWorksByAuthorIdPage({
    required String authorId,
    required int page,
    String? search,
    bool globalInfluential = false,
    int perPage = listPageSize,
  }) {
    return _fetchFilteredWorksPage(
      filter: 'authorships.author.id:$authorId',
      page: page,
      search: search,
      globalInfluential: globalInfluential,
      perPage: perPage,
    );
  }

  /// Wrapper trang 1 bài theo author.
  Future<List<Publication>> fetchWorksByAuthorId({
    required String authorId,
    String? search,
    bool globalInfluential = false,
    int maxPages = 1,
  }) async {
    final result = await fetchWorksByAuthorIdPage(
      authorId: authorId,
      page: 1,
      search: search,
      globalInfluential: globalInfluential,
    );
    return result.publications;
  }

  /// Bài của 1 institution — filter authorships.institutions.id.
  Future<OpenAlexWorksResult> fetchWorksByInstitutionIdPage({
    required String institutionId,
    required int page,
    String? search,
    bool globalInfluential = false,
    int perPage = listPageSize,
  }) {
    return _fetchFilteredWorksPage(
      filter: 'authorships.institutions.id:$institutionId',
      page: page,
      search: search,
      globalInfluential: globalInfluential,
      perPage: perPage,
    );
  }

  /// Bài của 1 journal/source — filter primary_location.source.id.
  Future<OpenAlexWorksResult> fetchWorksBySourceIdPage({
    required String sourceId,
    required int page,
    String? search,
    bool globalInfluential = false,
    int perPage = listPageSize,
  }) {
    return _fetchFilteredWorksPage(
      filter: 'primary_location.source.id:$sourceId',
      page: page,
      search: search,
      globalInfluential: globalInfluential,
      perPage: perPage,
    );
  }

  /// Wrapper trang 1 bài theo journal.
  Future<List<Publication>> fetchWorksBySourceId({
    required String sourceId,
    String? search,
    bool globalInfluential = false,
    int maxPages = 1,
  }) async {
    final result = await fetchWorksBySourceIdPage(
      sourceId: sourceId,
      page: 1,
      search: search,
      globalInfluential: globalInfluential,
    );
    return result.publications;
  }

  /// Bài liên quan từ field related_works — sort citations, bỏ bài hiện tại.
  Future<List<Publication>> fetchRelatedWorks({
    required List<String> relatedWorkIds,
    String? excludeWorkId,
    int limit = 5,
  }) async {
    final shortIds = relatedWorkIds
        .where((id) => id.isNotEmpty && id != excludeWorkId)
        .map(shortOpenAlexId)
        .where((id) => id.isNotEmpty)
        .take(limit)
        .toList();

    if (shortIds.isEmpty) return [];

    final page = await _fetchWorksPage(
      {
        'filter': 'ids.openalex:${shortIds.join('|')}',
        'sort': _sortByCitationsDesc,
      },
      page: 1,
      perPage: limit.clamp(1, _perPage),
    );

    return page.publications
        .where((paper) => paper.id != excludeWorkId)
        .toList();
  }

  /// Rút ID ngắn từ URL OpenAlex (https://openalex.org/W123 → W123).
  static String shortOpenAlexId(String openAlexId) {
    final trimmed = openAlexId.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('/')) {
      return trimmed.split('/').last;
    }
    return trimmed;
  }

  /// Trend theo năm của 1 concept — group_by publication_year + filter concepts.id.
  Future<Map<int, int>> fetchConceptYearlyTrend({
    required String conceptId,
    String? search,
    bool globalInfluential = false,
  }) async {
    final data = await _fetchWorksGroupBy(
      groupBy: 'publication_year',
      search: search,
      globalInfluential: false,
      filterOverride: _conceptFilter(
        conceptId: conceptId,
        search: search,
        globalInfluential: globalInfluential,
        includeTrendYears: true,
      ),
    );
    return parseGroupByYear(data);
  }

  /// Top authors trong phạm vi 1 concept.
  Future<List<OpenAlexRankedEntity>> fetchConceptTopAuthors({
    required String conceptId,
    String? search,
    bool globalInfluential = false,
    int limit = 5,
  }) {
    return fetchWorksGroupedCounts(
      groupBy: groupByAuthor,
      search: search,
      globalInfluential: globalInfluential,
      limit: limit,
      filterOverride: _conceptFilter(
        conceptId: conceptId,
        search: search,
        globalInfluential: globalInfluential,
      ),
    );
  }

  /// Top journals publish nhiều bài nhất trong concept.
  Future<List<OpenAlexRankedEntity>> fetchConceptTopJournals({
    required String conceptId,
    String? search,
    bool globalInfluential = false,
    int limit = 5,
  }) {
    return fetchWorksGroupedCounts(
      groupBy: groupByJournal,
      search: search,
      globalInfluential: globalInfluential,
      limit: limit,
      filterOverride: _conceptFilter(
        conceptId: conceptId,
        search: search,
        globalInfluential: globalInfluential,
      ),
    );
  }

  /// Danh sách bài thuộc concept — paginated (DomainDetailScreen).
  Future<OpenAlexWorksResult> fetchConceptWorksPage({
    required String conceptId,
    required int page,
    String? search,
    bool globalInfluential = false,
    int perPage = listPageSize,
  }) {
    return _fetchFilteredWorksPage(
      filter: _conceptFilter(
        conceptId: conceptId,
        search: search,
        globalInfluential: globalInfluential,
      ),
      page: page,
      search: search,
      globalInfluential: globalInfluential,
      perPage: perPage,
    );
  }

  String _topicFilter({
    required String topicId,
    String? search,
    bool globalInfluential = false,
    bool includeTrendYears = false,
  }) {
    return _scopedFilter(
      baseFilter: 'topics.id:$topicId',
      search: search,
      globalInfluential: globalInfluential,
      includeTrendYears: includeTrendYears,
    );
  }

  String _conceptFilter({
    required String conceptId,
    String? search,
    bool globalInfluential = false,
    bool includeTrendYears = false,
  }) {
    return _topicFilter(
      topicId: conceptId,
      search: search,
      globalInfluential: globalInfluential,
      includeTrendYears: includeTrendYears,
    );
  }

  String _authorFilter({
    required String authorId,
    String? search,
    bool globalInfluential = false,
    bool includeTrendYears = false,
  }) {
    return _scopedFilter(
      baseFilter: 'authorships.author.id:$authorId',
      search: search,
      globalInfluential: globalInfluential,
      includeTrendYears: includeTrendYears,
    );
  }

  String _sourceFilter({
    required String sourceId,
    String? search,
    bool globalInfluential = false,
    bool includeTrendYears = false,
  }) {
    return _scopedFilter(
      baseFilter: 'primary_location.source.id:$sourceId',
      search: search,
      globalInfluential: globalInfluential,
      includeTrendYears: includeTrendYears,
    );
  }

  String _institutionFilter({
    required String institutionId,
    String? search,
    bool globalInfluential = false,
    bool includeTrendYears = false,
  }) {
    return _scopedFilter(
      baseFilter: 'authorships.institutions.id:$institutionId',
      search: search,
      globalInfluential: globalInfluential,
      includeTrendYears: includeTrendYears,
    );
  }

  String _scopedFilter({
    required String baseFilter,
    String? search,
    bool globalInfluential = false,
    bool includeTrendYears = false,
  }) {
    var filter = baseFilter;
    if (includeTrendYears) {
      filter = '$filter,$_trendYearFilter';
    }
    if (globalInfluential && (search == null || search.trim().isEmpty)) {
      filter = '$filter,cited_by_count:>100';
    }
    return filter;
  }

  /// Trend theo năm của 1 author.
  Future<Map<int, int>> fetchAuthorYearlyTrend({
    required String authorId,
    String? search,
    bool globalInfluential = false,
  }) async {
    final data = await _fetchWorksGroupBy(
      groupBy: 'publication_year',
      search: search,
      globalInfluential: false,
      filterOverride: _authorFilter(
        authorId: authorId,
        search: search,
        globalInfluential: globalInfluential,
        includeTrendYears: true,
      ),
    );
    return parseGroupByYear(data);
  }

  /// Journal mà author publish nhiều nhất.
  Future<List<OpenAlexRankedEntity>> fetchAuthorTopJournals({
    required String authorId,
    String? search,
    bool globalInfluential = false,
    int limit = 5,
  }) {
    return fetchWorksGroupedCounts(
      groupBy: groupByJournal,
      search: search,
      globalInfluential: globalInfluential,
      limit: limit,
      filterOverride: _authorFilter(
        authorId: authorId,
        search: search,
        globalInfluential: globalInfluential,
      ),
    );
  }

  /// Trend theo năm của 1 journal/source.
  Future<Map<int, int>> fetchSourceYearlyTrend({
    required String sourceId,
    String? search,
    bool globalInfluential = false,
  }) async {
    final data = await _fetchWorksGroupBy(
      groupBy: 'publication_year',
      search: search,
      globalInfluential: false,
      filterOverride: _sourceFilter(
        sourceId: sourceId,
        search: search,
        globalInfluential: globalInfluential,
        includeTrendYears: true,
      ),
    );
    return parseGroupByYear(data);
  }

  /// Top authors publish nhiều trên journal này.
  Future<List<OpenAlexRankedEntity>> fetchSourceTopAuthors({
    required String sourceId,
    String? search,
    bool globalInfluential = false,
    int limit = 5,
  }) {
    return fetchWorksGroupedCounts(
      groupBy: groupByAuthor,
      search: search,
      globalInfluential: globalInfluential,
      limit: limit,
      filterOverride: _sourceFilter(
        sourceId: sourceId,
        search: search,
        globalInfluential: globalInfluential,
      ),
    );
  }

  /// Trend theo năm của 1 institution.
  Future<Map<int, int>> fetchInstitutionYearlyTrend({
    required String institutionId,
    String? search,
    bool globalInfluential = false,
  }) async {
    final data = await _fetchWorksGroupBy(
      groupBy: 'publication_year',
      search: search,
      globalInfluential: false,
      filterOverride: _institutionFilter(
        institutionId: institutionId,
        search: search,
        globalInfluential: globalInfluential,
        includeTrendYears: true,
      ),
    );
    return parseGroupByYear(data);
  }

  /// Top authors publish nhiều tại institution này.
  Future<List<OpenAlexRankedEntity>> fetchInstitutionTopAuthors({
    required String institutionId,
    String? search,
    bool globalInfluential = false,
    int limit = 5,
  }) {
    return fetchWorksGroupedCounts(
      groupBy: groupByAuthor,
      search: search,
      globalInfluential: globalInfluential,
      limit: limit,
      filterOverride: _institutionFilter(
        institutionId: institutionId,
        search: search,
        globalInfluential: globalInfluential,
      ),
    );
  }

  /// Tính % growth emerging topics — loop concept, gọi fetchConceptYearlyTrend.
  Future<List<TopicGrowthInsight>> fetchTopicGrowthInsights({
    required List<OpenAlexRankedEntity> concepts,
    String? search,
    bool globalInfluential = false,
    int limit = 5,
  }) async {
    final results = <TopicGrowthInsight>[];

    for (final concept in concepts.take(8)) {
      try {
        final trend = await fetchConceptYearlyTrend(
          conceptId: concept.id,
          search: search,
          globalInfluential: globalInfluential,
        );
        results.add(
          TopicGrowthInsight(
            id: concept.id,
            name: concept.name,
            growthPercent: ResearchInsights.computeConceptGrowth(trend),
          ),
        );
      } catch (_) {
        continue;
      }
    }

    results.sort((a, b) => b.growthPercent.compareTo(a.growthPercent));
    if (results.length <= limit) return results;
    return results.sublist(0, limit);
  }

  // ---------------------------------------------------------------------------
  // Tham số URL — quyết định sort/filter/search cho từng loại request
  // ---------------------------------------------------------------------------

  /// Search Explore: KHÔNG sort → relevance mặc định OpenAlex
  Map<String, String> _searchListParams(String search) {
    return {'search': search.trim()};
  }

  /// Dashboard global: bài từ 2000, có thể thêm cited_by_count:>100
  Map<String, String> _listBaseParams({
    String? search,
    bool globalInfluential = false,
  }) {
    if (search != null && search.trim().isNotEmpty) {
      // Đếm tổng / aggregate metrics khi đang search topic
      return _searchListParams(search);
    }

    var filter = 'publication_year:>${kAnalyticsStartYear - 1}';
    if (globalInfluential) {
      filter =
          'publication_year:>${kAnalyticsStartYear - 1},cited_by_count:>100';
    }

    return {
      'sort': _sortByCitationsDesc,
      'filter': filter,
    };
  }

  /// Citation Leaders: luôn sort citations dù search hay global.
  Map<String, String> _topPapersParams({
    String? search,
    bool globalInfluential = false,
  }) {
    if (search != null && search.trim().isNotEmpty) {
      return {
        'search': search.trim(),
        'sort': _sortByCitationsDesc,
      };
    }

    var filter = 'publication_year:>${kAnalyticsStartYear - 1}';
    if (globalInfluential) {
      filter =
          'publication_year:>${kAnalyticsStartYear - 1},cited_by_count:>100';
    }

    return {
      'sort': _sortByCitationsDesc,
      'filter': filter,
    };
  }

  Map<String, String> _yearListParams({
    required int year,
    String? search,
    bool globalInfluential = false,
  }) {
    return {
      'sort': _sortByCitationsDesc,
      'filter': _yearFilter(
        year: year,
        search: search,
        globalInfluential: globalInfluential,
      ),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
  }

  String _yearFilter({
    required int year,
    String? search,
    bool globalInfluential = false,
  }) {
    var filter = 'publication_year:$year';
    if (globalInfluential && (search == null || search.trim().isEmpty)) {
      filter = '$filter,cited_by_count:>100';
    }
    return filter;
  }

  /// GET /works có filter tùy ý + optional search — dùng cho author/journal/concept pages.
  Future<OpenAlexWorksResult> _fetchFilteredWorksPage({
    required String filter,
    required int page,
    String? search,
    bool globalInfluential = false,
    int perPage = listPageSize,
  }) {
    final params = <String, String>{
      'sort': _sortByCitationsDesc,
      'filter': filter,
    };

    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    } else if (globalInfluential) {
      params['filter'] = '$filter,cited_by_count:>100';
    }

    return _fetchWorksResultPage(params, page: page, perPage: perPage);
  }

  /// Wrapper _fetchWorksPage → OpenAlexWorksResult.
  Future<OpenAlexWorksResult> _fetchWorksResultPage(
    Map<String, String> baseParams, {
    required int page,
    int perPage = listPageSize,
  }) async {
    final pageResult = await _fetchWorksPage(
      baseParams,
      page: page,
      perPage: perPage,
    );

    return OpenAlexWorksResult(
      publications: pageResult.publications,
      totalOnOpenAlex: pageResult.totalOnOpenAlex,
    );
  }

  /// Gọi GET /works?group_by=... — trả raw JSON.
  Future<Map<String, dynamic>> _fetchWorksGroupBy({
    required String groupBy,
    String? search,
    bool globalInfluential = false,
    String? filterOverride,
  }) async {
    final queryParams = _worksGroupByParams(
      groupBy: groupBy,
      search: search,
      globalInfluential: globalInfluential,
      filterOverride: filterOverride,
    );
    final url = Uri.https(_apiHost, '/works', queryParams);
    return _getJson(url);
  }

  Map<String, String> _worksGroupByParams({
    required String groupBy,
    String? search,
    bool globalInfluential = false,
    String? filterOverride,
  }) {
    final queryParams = <String, String>{
      'group_by': groupBy,
      'mailto': _mailto,
    };

    final filter = filterOverride ??
        _defaultGroupByFilter(
          search: search,
          globalInfluential: globalInfluential,
        );
    if (filter != null && filter.isNotEmpty) {
      queryParams['filter'] = filter;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (_apiKey.isNotEmpty) {
      queryParams['api_key'] = _apiKey;
    }

    return queryParams;
  }

  /// Global dashboard và search topic đều giới hạn từ [kAnalyticsStartYear].
  String? _defaultGroupByFilter({
    String? search,
    bool globalInfluential = false,
  }) {
    if (globalInfluential) {
      return '$_trendYearFilter,cited_by_count:>100';
    }
    return _trendYearFilter;
  }

  /// Parse group_by publication_year → Map year → count
  static Map<int, int> parseGroupByYear(Map<String, dynamic> data) {
    final groups = data['group_by'] as List? ?? [];
    final result = <int, int>{};

    for (final group in groups) {
      if (group is! Map) continue;
      final key = group['key']?.toString();
      if (key == null || key == 'null') continue;

      final year = int.tryParse(key);
      if (year == null) continue;

      result[year] = (group['count'] as num?)?.toInt() ?? 0;
    }

    return filterYearlyFromAnalyticsStart(result);
  }

  /// Parse group_by open_access.is_oa → counts for true/false keys.
  static ({int openCount, int closedCount}) parseOpenAccessGroupBy(
    Map<String, dynamic> data,
  ) {
    final groups = data['group_by'] as List? ?? [];
    var openCount = 0;
    var closedCount = 0;

    for (final group in groups) {
      if (group is! Map) continue;
      final key = group['key'];
      final display = group['key_display_name']?.toString().toLowerCase();
      final count = (group['count'] as num?)?.toInt() ?? 0;
      if (_isOpenAccessGroupKey(key) || display == 'true' || display == 'open') {
        openCount += count;
      } else if (_isClosedAccessGroupKey(key) ||
          display == 'false' ||
          display == 'closed') {
        closedCount += count;
      } else {
        closedCount += count;
      }
    }

    return (openCount: openCount, closedCount: closedCount);
  }

  static bool _isOpenAccessGroupKey(Object? key) {
    if (key == true || key == 1) return true;
    final normalized = key?.toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  static bool _isClosedAccessGroupKey(Object? key) {
    if (key == false || key == 0) return true;
    final normalized = key?.toString().toLowerCase();
    return normalized == 'false' || normalized == '0';
  }

  /// Parse group_by author/journal/concept → list OpenAlexRankedEntity
  static List<OpenAlexRankedEntity> parseGroupByNamedCounts(
    Map<String, dynamic> data, {
    int limit = 10,
  }) {
    final groups = data['group_by'] as List? ?? [];
    final parsed = <OpenAlexRankedEntity>[];

    for (final group in groups) {
      if (group is! Map) continue;

      final key = group['key']?.toString();
      if (key == null || key == 'null') continue;

      final name = group['key_display_name']?.toString().trim();
      if (name == null || name.isEmpty) continue;

      parsed.add(
        OpenAlexRankedEntity(
          id: key,
          name: name,
          count: (group['count'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    parsed.sort((a, b) => b.count.compareTo(a.count));
    if (parsed.length <= limit) return parsed;
    return parsed.sublist(0, limit);
  }

  List<OpenAlexRankedEntity> _profilesToRankedByCitations(
    List<OpenAlexImpactProfile> profiles,
  ) {
    return profiles
        .where((profile) => profile.citedByCount > 0)
        .map(
          (profile) => OpenAlexRankedEntity(
            id: profile.id,
            name: profile.name,
            count: profile.citedByCount,
          ),
        )
        .toList();
  }

  Future<List<OpenAlexImpactProfile>> _fetchEntityImpactProfiles({
    required String entityPath,
    required String sort,
    String? search,
    bool globalInfluential = false,
    List<String>? topicIds,
    int limit = 10,
  }) async {
    final queryParams = _entityListParams(
      sort: sort,
      search: search,
      globalInfluential: globalInfluential,
      topicIds: topicIds,
    )
      ..['per-page'] = '${limit.clamp(1, _perPage)}'
      ..['page'] = '1';

    final url = Uri.https(_apiHost, '/$entityPath', queryParams);
    final data = await _getJson(url);
    return parseEntityImpactProfiles(data);
  }

  Map<String, String> _entityListParams({
    required String sort,
    String? search,
    bool globalInfluential = false,
    List<String>? topicIds,
  }) {
    final params = <String, String>{
      'sort': sort,
      'select': 'id,display_name,works_count,cited_by_count,summary_stats',
      'mailto': _mailto,
    };

    final topicFilter = _topicIdsFilter(topicIds);
    if (topicFilter != null) {
      params['filter'] = topicFilter;
    } else {
      final filter = _entityScopeFilter(globalInfluential: globalInfluential);
      if (filter.isNotEmpty) {
        params['filter'] = filter;
      }
    }

    if (_apiKey.isNotEmpty) {
      params['api_key'] = _apiKey;
    }

    return params;
  }

  String? _topicIdsFilter(List<String>? topicIds) {
    if (topicIds == null || topicIds.isEmpty) return null;
    final normalized = topicIds
        .map(shortOpenAlexId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.isEmpty) return null;
    return 'topics.id:${normalized.join('|')}';
  }

  String _entityScopeFilter({required bool globalInfluential}) {
    if (globalInfluential) {
      return 'cited_by_count:>100';
    }
    return 'works_count:>5';
  }

  /// Parse `/authors` hoặc `/institutions` list → impact profiles.
  static List<OpenAlexImpactProfile> parseEntityImpactProfiles(
    Map<String, dynamic> data,
  ) {
    final results = data['results'] as List? ?? [];
    final profiles = <OpenAlexImpactProfile>[];

    for (final item in results) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final id = map['id']?.toString();
      final name = map['display_name']?.toString().trim();
      if (id == null || id.isEmpty || name == null || name.isEmpty) {
        continue;
      }

      final summary = map['summary_stats'] as Map?;
      profiles.add(
        OpenAlexImpactProfile(
          id: id,
          name: name,
          worksCount: (map['works_count'] as num?)?.toInt() ?? 0,
          citedByCount: (map['cited_by_count'] as num?)?.toInt() ?? 0,
          hIndex: (summary?['h_index'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return profiles;
  }

  Future<OpenAlexWorksResult> _fetchWorksPaginated(
    Map<String, String> baseParams, {
    int maxPages = _searchListPages,
  }) async {
    final publications = <Publication>[];
    var totalOnOpenAlex = 0;

    for (var page = 1; page <= maxPages; page++) {
      final pageResult = await _fetchWorksPage(baseParams, page: page);

      totalOnOpenAlex = pageResult.totalOnOpenAlex;
      publications.addAll(pageResult.publications);

      if (pageResult.publications.length < _perPage) {
        break;
      }
    }

    return OpenAlexWorksResult(
      publications: publications,
      totalOnOpenAlex: totalOnOpenAlex,
    );
  }

  /// Gọi GET /works — parse JSON thành danh sách Publication + meta.count
  Future<OpenAlexWorksResult> _fetchWorksPage(
    Map<String, String> baseParams, {
    required int page,
    int perPage = _perPage,
  }) async {
    final queryParams = <String, String>{
      ...baseParams,
      'per-page': '$perPage',
      'page': '$page',
      'select': baseParams['select'] ?? _selectFields,
      'mailto': _mailto,
    };

    if (_apiKey.isNotEmpty) {
      queryParams['api_key'] = _apiKey;
    }

    final url = Uri.https(_apiHost, '/works', queryParams);
    final data = await _getJson(url);

    final List results = data['results'] ?? [];
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final total = (meta['count'] as num?)?.toInt() ?? results.length;

    final publications = results
          .map(
          (item) => Publication.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
          )
          .toList();

    return OpenAlexWorksResult(
      publications: publications,
      totalOnOpenAlex: total,
    );
  }

  // ---------------------------------------------------------------------------
  // HTTP layer — retry, timeout, parse JSON
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _getJson(Uri url) async {
    http.Response? lastResponse;

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _sendGetRequest(url);
        lastResponse = response;

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }

        if (_canRetryHttpStatus(response.statusCode, attempt)) {
          await _backoff(attempt);
          continue;
        }
        break;
      } on TimeoutException {
        await _retryOrFail(
          attempt,
          OpenAlexException(
            'OpenAlex khong phan hoi (timeout). Server co the dang qua tai - '
            'thu doi Wi-Fi/4G hoac bam Retry.',
          ),
        );
      } on SocketException {
        await _retryOrFail(
          attempt,
          OpenAlexException(
            'Khong ket noi duoc OpenAlex. Kiem tra internet tren thiet bi.',
          ),
        );
      } on http.ClientException catch (e) {
        await _retryOrFail(
          attempt,
          OpenAlexException('Loi mang khi goi OpenAlex: ${e.message}'),
        );
      }
    }

    if (lastResponse != null) {
      throw _mapHttpError(lastResponse);
    }

    throw OpenAlexException(
      'Khong tai duoc du lieu tu OpenAlex. Thu lai sau vai phut.',
    );
  }

  Future<http.Response> _sendGetRequest(Uri url) {
    return _httpClient
        .get(
          url,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'JournalTrendAnalyzer/1.0 (PRM393 Lab2)',
          },
        )
        .timeout(_requestTimeout);
  }

  bool _canRetryAttempt(int attempt) => attempt < _maxRetries - 1;

  bool _canRetryHttpStatus(int statusCode, int attempt) {
    return _retryStatusCodes.contains(statusCode) && _canRetryAttempt(attempt);
  }

  Future<void> _retryOrFail(int attempt, OpenAlexException failure) async {
    if (!_canRetryAttempt(attempt)) {
      throw failure;
    }
    await _backoff(attempt);
  }

  /// Chờ tăng dần giữa các lần retry (1.5s, 3s, 4.5s…).
  Future<void> _backoff(int attempt) async {
    await Future<void>.delayed(
      Duration(milliseconds: _retryBackoffMs * (attempt + 1)),
    );
  }

  /// Chuyển status HTTP → message tiếng Việt cho UI.
  OpenAlexException _mapHttpError(http.Response response) {
    final code = response.statusCode;

    switch (code) {
      case 429:
        return OpenAlexException(
          'OpenAlex giới hạn request (429). Đợi 30 giây rồi bấm Retry.',
          statusCode: code,
        );
      case 502:
      case 503:
      case 504:
        return OpenAlexException(
          'Máy chủ OpenAlex tạm bận (HTTP $code). '
          'App đã thử $_maxRetries lần — thử lại sau.',
          statusCode: code,
        );
      case 401:
      case 403:
        return OpenAlexException(
          'API key không hợp lệ (HTTP $code). '
          'Chạy app bằng .\\scripts\\run.ps1',
          statusCode: code,
        );
      default:
        return OpenAlexException(
          'Không tải được dữ liệu (HTTP $code). Kiểm tra mạng và thử lại.',
          statusCode: code,
        );
    }
  }
}
