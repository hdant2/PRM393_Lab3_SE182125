import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/openalex_ranked_entity.dart';
import '../models/openalex_works_result.dart';
import '../models/publication.dart';
import '../models/research_insight.dart';
import '../utils/research_insights.dart';
import 'openalex_exception.dart';

/// Service chịu trách nhiệm giao tiếp với OpenAlex API
class OpenAlexService {
  static const String _apiKey =
      String.fromEnvironment('OPENALEX_API_KEY');

  static const int _maxRetries = 4;
  static const Duration _requestTimeout = Duration(seconds: 45);
  static const Set<int> _retryStatusCodes = {429, 502, 503, 504};

  static const int _perPage = 100;
  static const int listPageSize = 20;
  static const int _searchListPages = 3;

  static const String groupByAuthor = 'authorships.author.id';
  static const String groupByJournal = 'primary_location.source.id';
  static const String groupByConcept = 'concepts.id';

  static const String _selectFields =
      'id,title,publication_year,cited_by_count,type,authorships,'
      'primary_location,best_oa_location,open_access,abstract_inverted_index,'
      'doi,concepts,related_works';

  String get _trendYearFilter {
    final endYear = DateTime.now().year;
    return 'publication_year:2016-$endYear';
  }

  List<int> get _trendYears {
    final endYear = DateTime.now().year;
    return [for (var year = 2016; year <= endYear; year++) year];
  }

  Future<OpenAlexWorksResult> searchPublications(String topic) {
    return fetchSearchPage(topic, page: 1);
  }

  Future<OpenAlexWorksResult> fetchSearchPage(
    String topic, {
    required int page,
    int perPage = listPageSize,
  }) {
    return _fetchWorksResultPage(
      _listBaseParams(search: topic),
      page: page,
      perPage: perPage,
    );
  }

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

  Future<List<Publication>> fetchTopPapers({
    String? search,
    bool globalInfluential = false,
    int limit = 10,
  }) async {
    final page = await _fetchWorksPage(
      _listBaseParams(
        search: search,
        globalInfluential: globalInfluential,
      ),
      page: 1,
      perPage: limit.clamp(1, _perPage),
    );
    return page.publications;
  }

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
    final data = await _fetchWorksGroupBy(
      groupBy: 'publication_year',
      search: search,
      globalInfluential: globalInfluential,
    );
    return parseGroupByYear(data);
  }

  Future<({Map<int, int> totals, Map<int, int> averages})>
      fetchCitationMetricsByYear({
    String? search,
    bool globalInfluential = false,
  }) async {
    final totals = <int, int>{};
    final averages = <int, int>{};

    for (final year in _trendYears) {
      final page = await _fetchWorksPage(
        {
          ..._yearListParams(
            year: year,
            search: search,
            globalInfluential: globalInfluential,
          ),
          'select': 'cited_by_count',
        },
        page: 1,
        perPage: _perPage,
      );

      if (page.publications.isEmpty) continue;

      final sum = page.publications.fold<int>(
        0,
        (total, paper) => total + paper.citations,
      );
      totals[year] = sum;
      averages[year] = (sum / page.publications.length).round();
    }

    return (totals: totals, averages: averages);
  }

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

  /// Lấy các bài liên quan từ danh sách OpenAlex work id (`related_works`)
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
        'sort': 'cited_by_count:desc',
      },
      page: 1,
      perPage: limit.clamp(1, _perPage),
    );

    return page.publications
        .where((paper) => paper.id != excludeWorkId)
        .toList();
  }

  static String shortOpenAlexId(String openAlexId) {
    final trimmed = openAlexId.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('/')) {
      return trimmed.split('/').last;
    }
    return trimmed;
  }

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

  String _conceptFilter({
    required String conceptId,
    String? search,
    bool globalInfluential = false,
    bool includeTrendYears = false,
  }) {
    return _scopedFilter(
      baseFilter: 'concepts.id:$conceptId',
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

  Map<String, String> _listBaseParams({
    String? search,
    bool globalInfluential = false,
  }) {
    if (search != null && search.trim().isNotEmpty) {
      return {
        'search': search.trim(),
        'sort': 'cited_by_count:desc',
      };
    }

    var filter = 'publication_year:>2015';
    if (globalInfluential) {
      filter = 'publication_year:>2015,cited_by_count:>100';
    }

    return {
      'sort': 'cited_by_count:desc',
      'filter': filter,
    };
  }

  Map<String, String> _yearListParams({
    required int year,
    String? search,
    bool globalInfluential = false,
  }) {
    return {
      'sort': 'cited_by_count:desc',
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

  Future<OpenAlexWorksResult> _fetchFilteredWorksPage({
    required String filter,
    required int page,
    String? search,
    bool globalInfluential = false,
    int perPage = listPageSize,
  }) {
    final params = <String, String>{
      'sort': 'cited_by_count:desc',
      'filter': filter,
    };

    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    } else if (globalInfluential) {
      params['filter'] = '$filter,cited_by_count:>100';
    }

    return _fetchWorksResultPage(params, page: page, perPage: perPage);
  }

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
    final url = Uri.https('api.openalex.org', '/works', queryParams);
    return _getJson(url);
  }

  Map<String, String> _worksGroupByParams({
    required String groupBy,
    String? search,
    bool globalInfluential = false,
    String? filterOverride,
  }) {
    var filter = filterOverride ?? _trendYearFilter;
    if (filterOverride == null &&
        globalInfluential &&
        (search == null || search.trim().isEmpty)) {
      filter = '$_trendYearFilter,cited_by_count:>100';
    }

    final queryParams = <String, String>{
      'group_by': groupBy,
      'filter': filter,
      'mailto': 'prm393.lab2@example.com',
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (_apiKey.isNotEmpty) {
      queryParams['api_key'] = _apiKey;
    }

    return queryParams;
  }

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

    return result;
  }

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
      'mailto': 'prm393.lab2@example.com',
    };

    if (_apiKey.isNotEmpty) {
      queryParams['api_key'] = _apiKey;
    }

    final url = Uri.https('api.openalex.org', '/works', queryParams);
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

  Future<Map<String, dynamic>> _getJson(Uri url) async {
    http.Response? lastResponse;

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http
            .get(
              url,
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'JournalTrendAnalyzer/1.0 (PRM393 Lab2)',
              },
            )
            .timeout(_requestTimeout);

        lastResponse = response;

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }

        if (_retryStatusCodes.contains(response.statusCode) &&
            attempt < _maxRetries - 1) {
          await _backoff(attempt);
          continue;
        }

        break;
      } on TimeoutException {
        if (attempt < _maxRetries - 1) {
          await _backoff(attempt);
          continue;
        }
        throw OpenAlexException(
          'OpenAlex không phản hồi (timeout). Server có thể đang quá tải — '
          'thử đổi Wi‑Fi/4G hoặc bấm Retry.',
        );
      } on SocketException {
        if (attempt < _maxRetries - 1) {
          await _backoff(attempt);
          continue;
        }
        throw OpenAlexException(
          'Không kết nối được OpenAlex. Kiểm tra internet trên thiết bị.',
        );
      } on http.ClientException catch (e) {
        if (attempt < _maxRetries - 1) {
          await _backoff(attempt);
          continue;
        }
        throw OpenAlexException(
          'Lỗi mạng khi gọi OpenAlex: ${e.message}',
        );
      }
    }

    if (lastResponse != null) {
      throw _mapHttpError(lastResponse);
    }

    throw OpenAlexException(
      'Không tải được dữ liệu từ OpenAlex. Thử lại sau vài phút.',
    );
  }

  Future<void> _backoff(int attempt) async {
    await Future<void>.delayed(
      Duration(milliseconds: 1500 * (attempt + 1)),
    );
  }

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
