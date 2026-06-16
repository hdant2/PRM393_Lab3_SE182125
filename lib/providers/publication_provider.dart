import 'package:flutter/material.dart';

import '../models/openalex_ranked_entity.dart';
import '../models/openalex_works_result.dart';
import '../models/publication.dart';
import '../models/research_insight.dart';
import '../services/openalex_config.dart';
import '../services/openalex_exception.dart';
import '../services/openalex_service.dart';
import '../services/recent_searches_service.dart';
import '../utils/count_format.dart';
import '../utils/research_insights.dart';

// =============================================================================
// publication_provider.dart — TẦNG STATE (Provider pattern)
// =============================================================================
// UI không gọi OpenAlex trực tiếp — chỉ đọc/ghi qua class này.
//
// Hai chế độ phân tích:
//   AnalysisScope.global → Overview/Analytics mặc định (bài influential sau 2015)
//   AnalysisScope.topic  → user search "ras", "AI"… trên Explore
//
// Luồng search (Explore):
//   1. searchPublications() — load 20 bài trang 1 NGAY (isSearchLoading)
//   2. _loadSearchMetricsInBackground() — trend, top author, journal… (isTrendLoading)
//   3. loadMoreSearchPublications() — cuộn xuống load thêm 20 bài
//
// _searchGeneration: tránh race condition — search cũ không ghi đè search mới
// =============================================================================

/// global = dashboard mặc định; topic = đang search một chủ đề
enum AnalysisScope { global, topic }

/// ChangeNotifier: khi data đổi → notifyListeners() → UI rebuild
class PublicationProvider extends ChangeNotifier {
  PublicationProvider({required OpenAlexConfig config})
      : _config = config,
        _openAlexService = OpenAlexService(config),
        _recentSearchesService = RecentSearchesService();

  final OpenAlexConfig _config;
  final OpenAlexService _openAlexService;
  final RecentSearchesService _recentSearchesService;

  static const globalTopicLabel = 'Global Research Overview';

  // --- Phạm vi hiện tại ---
  AnalysisScope scope = AnalysisScope.global;
  String currentTopic = globalTopicLabel;

  // --- Dữ liệu hiển thị trên UI ---
  List<Publication> publications = []; // danh sách chính (search / global list)
  List<Publication> topPapersOpenAlex = []; // Citation Leaders (top 10 cited)
  Map<int, int> yearlyTrendFromOpenAlex = {}; // năm → số bài
  Map<int, int> citationsByYearOpenAlex = {};
  Map<int, int> avgCitationsByYearOpenAlex = {};
  List<OpenAlexRankedEntity> topAuthorsOpenAlex = [];
  List<OpenAlexRankedEntity> topJournalsOpenAlex = [];
  List<OpenAlexRankedEntity> topResearchAreasOpenAlex = [];
  List<TopicGrowthInsight> growingTopicsOpenAlex = [];
  double averageCitationOpenAlex = 0;
  int totalOnOpenAlex = 0; // meta.count từ API (~201K khi search "ras")

  // --- Trạng thái loading (tách riêng để UI không spin cả màn) ---
  bool isDashboardLoading = false;
  bool isSearchLoading = false; // đang load 20 bài đầu search
  bool isTrendLoading = false; // đang load metrics phụ (chart, top author…)
  bool isLoadingMorePublications = false;
  bool searchHasMore = false;
  int searchListPage = 0;
  String? errorMessage;
  List<String> recentSearches = [];

  /// Tăng mỗi lần user search — request cũ bị bỏ qua nếu generation không khớp
  int _searchGeneration = 0;

  bool get isLoading =>
      isDashboardLoading || isSearchLoading || isTrendLoading;
  bool get hasData =>
      totalOnOpenAlex > 0 ||
      yearlyTrendFromOpenAlex.isNotEmpty ||
      topPapersOpenAlex.isNotEmpty;
  bool get isGlobalScope => scope == AnalysisScope.global;
  bool get hasRealTrend => yearlyTrendFromOpenAlex.isNotEmpty;

  List<OpenAlexRankedEntity> get rankedAuthors => topAuthorsOpenAlex;
  List<OpenAlexRankedEntity> get rankedJournals => topJournalsOpenAlex;
  List<OpenAlexRankedEntity> get trendingAreas => topResearchAreasOpenAlex;

  String get formattedTotalOnOpenAlex => formatOpenAlexCount(totalOnOpenAlex);

  TrendInsight get trendInsight => ResearchInsights.analyzeTrend(
        volumeByYear: yearlyTrendFromOpenAlex,
        citationsByYear: citationsByYearOpenAlex,
        topicLabel: isGlobalScope ? 'Global research' : currentTopic,
      );

  LandscapePulse get landscapePulse => ResearchInsights.buildLandscapePulse(
        totalPublications: totalOnOpenAlex,
        volumeByYear: yearlyTrendFromOpenAlex,
        averageCitations: averageCitationOpenAlex,
      );

  TopicSnapshot? get topicSnapshot {
    if (isGlobalScope) return null;
    return ResearchInsights.buildTopicSnapshot(
      topic: currentTopic,
      totalPublications: totalOnOpenAlex,
      volumeByYear: yearlyTrendFromOpenAlex,
      citationsByYear: citationsByYearOpenAlex,
      topJournal: topJournalsOpenAlex.isEmpty ? null : topJournalsOpenAlex.first,
    );
  }

  String get influentialPapersInsight =>
      ResearchInsights.influentialPapersInsight(topPapersOpenAlex);

  String get researchLeadersInsight =>
      ResearchInsights.researchLeadersInsight(topAuthorsOpenAlex);

  String get journalPowerInsight =>
      ResearchInsights.journalPowerInsight(topJournalsOpenAlex);

  String get mostActiveYearLabel {
    if (yearlyTrendFromOpenAlex.isEmpty) return 'N/A';
    final peak = yearlyTrendFromOpenAlex.entries
        .reduce((a, b) => a.value >= b.value ? a : b);
    return '${peak.key} (${formatOpenAlexCount(peak.value)})';
  }

  OpenAlexRankedEntity? rankedAuthorByName(String name) {
    for (final author in topAuthorsOpenAlex) {
      if (author.name == name) return author;
    }
    return null;
  }

  OpenAlexRankedEntity? rankedJournalByName(String name) {
    for (final journal in topJournalsOpenAlex) {
      if (journal.name == name) return journal;
    }
    return null;
  }

  /// Mở app / "Back to global overview" — load dashboard toàn cục
  Future<void> loadDefaultDashboard() async {
    isDashboardLoading = true;
    isTrendLoading = true;
    errorMessage = null;
    publications = [];
    notifyListeners();

    try {
      scope = AnalysisScope.global;
      currentTopic = globalTopicLabel;

      totalOnOpenAlex = await _openAlexService.fetchWorksTotalCount(
        globalInfluential: true,
      );
      isDashboardLoading = false;
      notifyListeners();

      await _loadAllOpenAlexMetrics(globalInfluential: true);
    } catch (e) {
      _clearAllData();
      errorMessage = _mapError(e);
    } finally {
      isDashboardLoading = false;
      isTrendLoading = false;
      notifyListeners();
    }
  }

  /// User bấm search trên Explore — 2 phase: bài trước, metrics sau
  Future<void> searchPublications(String topic) async {
    final generation = ++_searchGeneration;
    final trimmed = topic.trim();
    if (trimmed.isEmpty) return;

    recentSearches = await _recentSearchesService.add(trimmed);

    isSearchLoading = true;
    scope = AnalysisScope.topic;
    currentTopic = trimmed;
    errorMessage = null;
    searchListPage = 0;
    searchHasMore = false;
    publications = [];
    _clearTopicMetrics(); // xóa số global cũ để không hiện 937K nhầm
    notifyListeners();

    try {
      // Phase 1: 20 bài relevance (giống OpenAlex web)
      final works = await _openAlexService.searchPublications(trimmed);
      if (generation != _searchGeneration) return;

      publications = works.publications;
      totalOnOpenAlex = works.totalOnOpenAlex;
      searchListPage = 1;
      searchHasMore = works.hasMore(publications.length);
    } catch (e) {
      if (generation != _searchGeneration) return;

      _clearAllData();
      errorMessage = _mapError(e);
    } finally {
      if (generation == _searchGeneration) {
        isSearchLoading = false;
        notifyListeners();
      }
    }

    if (generation != _searchGeneration) return;
    // Phase 2: trend, top author/journal — không chặn danh sách bài
    _loadSearchMetricsInBackground(trimmed, generation);
  }

  /// Đọc recent searches từ SharedPreferences (tab Home).
  Future<void> loadRecentSearches() async {
    recentSearches = await _recentSearchesService.load();
    notifyListeners();
  }

  /// Xóa toàn bộ lịch sử search.
  Future<void> clearRecentSearches() async {
    recentSearches = await _recentSearchesService.clear();
    notifyListeners();
  }

  /// Gọi nền sau khi 20 bài đã hiện — isTrendLoading = true trong lúc chờ
  void _loadSearchMetricsInBackground(String topic, int generation) {
    isTrendLoading = true;
    notifyListeners();

    _loadAllOpenAlexMetrics(search: topic).then((_) {
      if (generation != _searchGeneration) return;
      isTrendLoading = false;
      notifyListeners();
    }).catchError((_) {
      if (generation != _searchGeneration) return;
      isTrendLoading = false;
      notifyListeners();
    });
  }

  /// true khi topic snapshot (Growth, Momentum…) đã load xong
  bool get isTopicInsightsReady => !isGlobalScope && !isTrendLoading;

  /// Cuộn Explore — load trang search tiếp theo (+20 bài).
  Future<void> loadMoreSearchPublications() async {
    if (!searchHasMore || isLoadingMorePublications || isGlobalScope) return;

    final generation = _searchGeneration;
    isLoadingMorePublications = true;
    notifyListeners();

    try {
      final nextPage = searchListPage + 1;
      final works = await _openAlexService.fetchSearchPage(
        currentTopic,
        page: nextPage,
      );
      if (generation != _searchGeneration) return;

      publications = [...publications, ...works.publications];
      searchListPage = nextPage;
      searchHasMore = works.hasMore(publications.length);
    } catch (e) {
      if (generation != _searchGeneration) return;
      errorMessage = _mapError(e);
    } finally {
      if (generation == _searchGeneration) {
        isLoadingMorePublications = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Delegate load* — màn detail gọi qua đây, tự gắn search/global filter
  // ---------------------------------------------------------------------------

  /// Pull-to-refresh — reload dashboard hoặc search hiện tại.
  Future<void> refreshCurrentAnalysis() async {
    if (isGlobalScope) {
      await loadDefaultDashboard();
    } else {
      await searchPublications(currentTopic);
    }
  }

  /// YearDetailScreen — bài của 1 năm (scoped search nếu có).
  Future<List<Publication>> loadPublicationsForYear(int year) {
    if (isGlobalScope) {
      return _openAlexService.fetchPublicationsForYear(
        year: year,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchPublicationsForYear(
      year: year,
      search: currentTopic,
    );
  }

  /// YearDetail — phân trang bài theo năm.
  Future<OpenAlexWorksResult> loadPublicationsForYearPage(
    int year,
    int page,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchPublicationsForYearPage(
        year: year,
        page: page,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchPublicationsForYearPage(
      year: year,
      page: page,
      search: currentTopic,
    );
  }

  /// Hot topics chips trên YearDetail.
  Future<List<OpenAlexRankedEntity>> loadConceptsForYear(int year) {
    if (isGlobalScope) {
      return _openAlexService.fetchConceptsForYear(
        year: year,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchConceptsForYear(
      year: year,
      search: currentTopic,
    );
  }

  Future<List<Publication>> loadWorksByAuthor(OpenAlexRankedEntity author) {
    if (isGlobalScope) {
      return _openAlexService.fetchWorksByAuthorId(
        authorId: author.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchWorksByAuthorId(
      authorId: author.id,
      search: currentTopic,
    );
  }

  Future<OpenAlexWorksResult> loadWorksByAuthorPage(
    OpenAlexRankedEntity author,
    int page,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchWorksByAuthorIdPage(
        authorId: author.id,
        page: page,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchWorksByAuthorIdPage(
      authorId: author.id,
      page: page,
      search: currentTopic,
    );
  }

  /// DetailScreen — related works từ OpenAlex.
  Future<List<Publication>> loadRelatedWorks(Publication publication) {
    return _openAlexService.fetchRelatedWorks(
      relatedWorkIds: publication.relatedWorkIds,
      excludeWorkId: publication.id,
    );
  }

  /// DomainDetail — trend chart của concept.
  Future<Map<int, int>> loadConceptTrend(OpenAlexRankedEntity concept) {
    if (isGlobalScope) {
      return _openAlexService.fetchConceptYearlyTrend(
        conceptId: concept.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchConceptYearlyTrend(
      conceptId: concept.id,
      search: currentTopic,
    );
  }

  /// DomainDetail — top authors trong concept.
  Future<List<OpenAlexRankedEntity>> loadConceptTopAuthors(
    OpenAlexRankedEntity concept,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchConceptTopAuthors(
        conceptId: concept.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchConceptTopAuthors(
      conceptId: concept.id,
      search: currentTopic,
    );
  }

  /// DomainDetail — top journals trong concept.
  Future<List<OpenAlexRankedEntity>> loadConceptTopJournals(
    OpenAlexRankedEntity concept,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchConceptTopJournals(
        conceptId: concept.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchConceptTopJournals(
      conceptId: concept.id,
      search: currentTopic,
    );
  }

  /// DomainDetail — papers paginated (gọi từ _load / _loadMorePapers).
  Future<OpenAlexWorksResult> loadConceptWorksPage(
    OpenAlexRankedEntity concept,
    int page,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchConceptWorksPage(
        conceptId: concept.id,
        page: page,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchConceptWorksPage(
      conceptId: concept.id,
      page: page,
      search: currentTopic,
    );
  }

  /// AuthorDetail — trend theo năm.
  Future<Map<int, int>> loadAuthorTrend(OpenAlexRankedEntity author) {
    if (isGlobalScope) {
      return _openAlexService.fetchAuthorYearlyTrend(
        authorId: author.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchAuthorYearlyTrend(
      authorId: author.id,
      search: currentTopic,
    );
  }

  /// AuthorDetail — top journals của author.
  Future<List<OpenAlexRankedEntity>> loadAuthorTopJournals(
    OpenAlexRankedEntity author,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchAuthorTopJournals(
        authorId: author.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchAuthorTopJournals(
      authorId: author.id,
      search: currentTopic,
    );
  }

  /// JournalDetail — trend theo năm.
  Future<Map<int, int>> loadJournalTrend(OpenAlexRankedEntity journal) {
    if (isGlobalScope) {
      return _openAlexService.fetchSourceYearlyTrend(
        sourceId: journal.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchSourceYearlyTrend(
      sourceId: journal.id,
      search: currentTopic,
    );
  }

  /// JournalDetail — top authors trên journal.
  Future<List<OpenAlexRankedEntity>> loadJournalTopAuthors(
    OpenAlexRankedEntity journal,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchSourceTopAuthors(
        sourceId: journal.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchSourceTopAuthors(
      sourceId: journal.id,
      search: currentTopic,
    );
  }

  OpenAlexRankedEntity? rankedConceptById(String id) {
    for (final area in topResearchAreasOpenAlex) {
      if (area.id == id) return area;
    }
    for (final topic in growingTopicsOpenAlex) {
      if (topic.id == id) {
        return OpenAlexRankedEntity(id: topic.id, name: topic.name, count: 0);
      }
    }
    return null;
  }

  OpenAlexConfig get openAlexConfig => _config;

  Future<void> saveOpenAlexApiKey(String key) async {
    await _config.saveKey(key);
    notifyListeners();
  }

  Future<void> clearOpenAlexApiKey() async {
    await _config.clearSavedKey();
    notifyListeners();
  }

  Future<List<Publication>> loadWorksByJournal(
    OpenAlexRankedEntity journal,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchWorksBySourceId(
        sourceId: journal.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchWorksBySourceId(
      sourceId: journal.id,
      search: currentTopic,
    );
  }

  Future<OpenAlexWorksResult> loadWorksByJournalPage(
    OpenAlexRankedEntity journal,
    int page,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchWorksBySourceIdPage(
        sourceId: journal.id,
        page: page,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchWorksBySourceIdPage(
      sourceId: journal.id,
      page: page,
      search: currentTopic,
    );
  }

  int openAlexCountForYear(int year) {
    return yearlyTrendFromOpenAlex[year] ?? 0;
  }

  /// Xóa metrics topic khi search mới — tránh hiện số global cũ.
  void _clearTopicMetrics() {
    topPapersOpenAlex = [];
    yearlyTrendFromOpenAlex = {};
    citationsByYearOpenAlex = {};
    avgCitationsByYearOpenAlex = {};
    topAuthorsOpenAlex = [];
    topJournalsOpenAlex = [];
    topResearchAreasOpenAlex = [];
    growingTopicsOpenAlex = [];
    averageCitationOpenAlex = 0;
    totalOnOpenAlex = 0;
  }

  /// Reset toàn bộ state khi lỗi nặng.
  void _clearAllData() {
    publications = [];
    _clearTopicMetrics();
    searchHasMore = false;
    searchListPage = 0;
  }

  /// OpenAlexException → string hiển thị ErrorBanner.
  String _mapError(Object e) {
    return e is OpenAlexException
        ? e.message
        : e.toString().replaceFirst('Exception: ', '');
  }

  /// Gom mọi metrics OpenAlex (gọi song song tuần tự trong hàm này)
  Future<void> _loadAllOpenAlexMetrics({
    String? search,
    bool globalInfluential = false,
  }) async {
    isTrendLoading = true;
    notifyListeners();

    // group_by publication_year → biểu đồ trend
    yearlyTrendFromOpenAlex = await _tryAggregate(
      () => _openAlexService.fetchPublicationTrendByYear(
        search: search,
        globalInfluential: globalInfluential,
      ),
      {},
    );

    topAuthorsOpenAlex = await _tryAggregate(
      () => _openAlexService.fetchWorksGroupedCounts(
        groupBy: OpenAlexService.groupByAuthor,
        search: search,
        globalInfluential: globalInfluential,
      ),
      [],
    );

    topJournalsOpenAlex = await _tryAggregate(
      () => _openAlexService.fetchWorksGroupedCounts(
        groupBy: OpenAlexService.groupByJournal,
        search: search,
        globalInfluential: globalInfluential,
      ),
      [],
    );

    topResearchAreasOpenAlex = await _tryAggregate(
      () => _openAlexService.fetchWorksGroupedCounts(
        groupBy: OpenAlexService.groupByConcept,
        search: search,
        globalInfluential: globalInfluential,
        limit: 8,
      ),
      [],
    );

    growingTopicsOpenAlex = await _tryAggregate(
      () => _openAlexService.fetchTopicGrowthInsights(
        concepts: topResearchAreasOpenAlex,
        search: search,
        globalInfluential: globalInfluential,
        limit: 5,
      ),
      [],
    );

    topPapersOpenAlex = await _tryAggregate(
      () => _openAlexService.fetchTopPapers(
        search: search,
        globalInfluential: globalInfluential,
        limit: 10,
      ),
      [],
    ); // sort citations — khác danh sách Explore (relevance)

    averageCitationOpenAlex = await _tryAggregate(
      () => _openAlexService.fetchAverageCitation(
        search: search,
        globalInfluential: globalInfluential,
      ),
      0.0,
    );

    final citationMetrics = await _tryAggregate(
      () => _openAlexService.fetchCitationMetricsByYear(
        search: search,
        globalInfluential: globalInfluential,
      ),
      (totals: <int, int>{}, averages: <int, int>{}),
    );
    citationsByYearOpenAlex = citationMetrics.totals;
    avgCitationsByYearOpenAlex = citationMetrics.averages;

    isTrendLoading = false;
    notifyListeners();
  }

  /// Một API lỗi không làm crash cả dashboard — trả fallback rỗng/0
  Future<T> _tryAggregate<T>(Future<T> Function() load, T fallback) async {
    try {
      return await load();
    } catch (_) {
      return fallback;
    }
  }
}
