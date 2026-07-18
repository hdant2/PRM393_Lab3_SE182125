import 'package:flutter/material.dart';

import '../models/openalex_impact_profile.dart';
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
import '../services/analytics_service.dart';

// =============================================================================
// publication_provider.dart ΓÇö Tß║ªNG STATE (Provider pattern)
// =============================================================================
// UI kh├┤ng gß╗ìi OpenAlex trß╗▒c tiß║┐p ΓÇö chß╗ë ─æß╗ìc/ghi qua class n├áy.
//
// Hai chß║┐ ─æß╗Ö ph├ón t├¡ch:
//   AnalysisScope.global ΓåÆ Overview/Analytics mß║╖c ─æß╗ïnh (b├ái influential sau 2015)
//   AnalysisScope.topic  ΓåÆ user search "ras", "AI"ΓÇª tr├¬n Explore
//
// Luß╗ông search (Explore):
//   1. searchPublications() ΓÇö load 20 b├ái trang 1 NGAY (isSearchLoading)
//   2. _loadSearchMetricsInBackground() ΓÇö trend, top author, journalΓÇª (isTrendLoading)
//   3. loadMoreSearchPublications() ΓÇö cuß╗Ön xuß╗æng load th├¬m 20 b├ái
//
// _searchGeneration: tr├ính race condition ΓÇö search c┼⌐ kh├┤ng ghi ─æ├¿ search mß╗¢i
// =============================================================================

/// global = dashboard mß║╖c ─æß╗ïnh; topic = ─æang search mß╗Öt chß╗º ─æß╗ü
enum AnalysisScope { global, topic }

/// ChangeNotifier: khi data ─æß╗òi ΓåÆ notifyListeners() ΓåÆ UI rebuild
class PublicationViewModel extends ChangeNotifier {
  PublicationViewModel({
    required OpenAlexConfig config,
    OpenAlexService? openAlexService,
    RecentSearchesService? recentSearchesService,
  })  : _config = config,
        _openAlexService = openAlexService ?? OpenAlexService(config),
        _recentSearchesService =
            recentSearchesService ?? RecentSearchesService();

  final OpenAlexConfig _config;
  final OpenAlexService _openAlexService;
  final RecentSearchesService _recentSearchesService;

  static const globalTopicLabel = 'Global Research Overview';

  // --- Phß║ím vi hiß╗çn tß║íi ---
  AnalysisScope scope = AnalysisScope.global;
  String currentTopic = globalTopicLabel;

  // --- Dß╗» liß╗çu hiß╗ân thß╗ï tr├¬n UI ---
  List<Publication> publications = []; // danh s├ích ch├¡nh (search / global list)
  List<Publication> topPapersOpenAlex = []; // Citation Leaders (top 10 cited)
  Map<int, int> yearlyTrendFromOpenAlex = {}; // n─âm ΓåÆ sß╗æ b├ái
  Map<int, int> monthlyTrendFromOpenAlex = {}; // th├íng 1ΓÇô12 trong n─âm hiß╗çn tß║íi
  Map<int, int> citationsByYearOpenAlex = {};
  Map<int, int> avgCitationsByYearOpenAlex = {};
  List<OpenAlexRankedEntity> topAuthorsOpenAlex = [];
  List<OpenAlexRankedEntity> topJournalsOpenAlex = [];
  List<OpenAlexRankedEntity> topResearchAreasOpenAlex = [];
  List<OpenAlexRankedEntity> topInstitutionsOpenAlex = [];
  List<OpenAlexRankedEntity> worksByTypeOpenAlex = [];
  List<OpenAlexRankedEntity> topAuthorsByCitationsOpenAlex = [];
  List<OpenAlexRankedEntity> topInstitutionsByCitationsOpenAlex = [];
  List<OpenAlexRankedEntity> topAuthorsByHIndexOpenAlex = [];
  List<OpenAlexRankedEntity> countriesOpenAlex = [];
  List<OpenAlexImpactProfile> authorImpactProfilesOpenAlex = [];
  int openAccessCountOpenAlex = 0;
  int closedAccessCountOpenAlex = 0;
  List<TopicGrowthInsight> growingTopicsOpenAlex = [];
  double averageCitationOpenAlex = 0;
  int totalOnOpenAlex = 0; // meta.count tß╗½ API (~201K khi search "ras")

  // --- Trß║íng th├íi loading (t├ích ri├¬ng ─æß╗â UI kh├┤ng spin cß║ú m├án) ---
  bool isDashboardLoading = false;
  bool isSearchLoading = false; // ─æang load 20 b├ái ─æß║ºu search
  bool isTrendLoading = false; // ─æang load metrics phß╗Ñ (chart, top authorΓÇª)
  bool isLoadingMorePublications = false;
  bool searchHasMore = false;
  int searchListPage = 0;
  String? errorMessage;
  List<String> recentSearches = [];

  /// T─âng mß╗ùi lß║ºn user search ΓÇö request c┼⌐ bß╗ï bß╗Å qua nß║┐u generation kh├┤ng khß╗¢p
  int _searchGeneration = 0;

  // Snapshot dashboard global ΓÇö Overview ─æß╗ìc tß╗½ ─æ├óy, kh├┤ng bß╗ï search Explore ghi ─æ├¿
  int _dashboardTotalOnOpenAlex = 0;
  Map<int, int> _dashboardYearlyTrendFromOpenAlex = {};
  Map<int, int> _dashboardMonthlyTrendFromOpenAlex = {};
  Map<int, int> _dashboardCitationsByYearOpenAlex = {};
  List<OpenAlexRankedEntity> _dashboardTopAuthorsOpenAlex = [];
  List<OpenAlexRankedEntity> _dashboardTopJournalsOpenAlex = [];
  List<OpenAlexRankedEntity> _dashboardTopResearchAreasOpenAlex = [];
  List<OpenAlexRankedEntity> _dashboardTopInstitutionsOpenAlex = [];
  List<OpenAlexRankedEntity> _dashboardWorksByTypeOpenAlex = [];
  List<OpenAlexRankedEntity> _dashboardTopAuthorsByCitationsOpenAlex = [];
  List<OpenAlexRankedEntity> _dashboardTopInstitutionsByCitationsOpenAlex = [];
  List<OpenAlexRankedEntity> _dashboardTopAuthorsByHIndexOpenAlex = [];
  List<OpenAlexRankedEntity> _dashboardCountriesOpenAlex = [];
  List<OpenAlexImpactProfile> _dashboardAuthorImpactProfilesOpenAlex = [];
  int _dashboardOpenAccessCount = 0;
  int _dashboardClosedAccessCount = 0;
  List<TopicGrowthInsight> _dashboardGrowingTopicsOpenAlex = [];
  List<Publication> _dashboardTopPapersOpenAlex = [];
  double _dashboardAverageCitationOpenAlex = 0;

  bool get isLoading =>
      isDashboardLoading || isSearchLoading || isTrendLoading;
  bool get hasData =>
      totalOnOpenAlex > 0 ||
      yearlyTrendFromOpenAlex.isNotEmpty ||
      topPapersOpenAlex.isNotEmpty;
  bool get hasDashboardData =>
      _dashboardTotalOnOpenAlex > 0 ||
      _dashboardYearlyTrendFromOpenAlex.isNotEmpty ||
      _dashboardTopPapersOpenAlex.isNotEmpty;
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

  int get dashboardTotalOnOpenAlex => _dashboardTotalOnOpenAlex;
  Map<int, int> get dashboardYearlyTrendFromOpenAlex =>
      _dashboardYearlyTrendFromOpenAlex;
  Map<int, int> get dashboardMonthlyTrendFromOpenAlex =>
      _dashboardMonthlyTrendFromOpenAlex;
  Map<int, int> get dashboardCitationsByYearOpenAlex =>
      _dashboardCitationsByYearOpenAlex;
  double get dashboardAverageCitationOpenAlex =>
      _dashboardAverageCitationOpenAlex;
  List<OpenAlexRankedEntity> get dashboardTrendingAreas =>
      _dashboardTopResearchAreasOpenAlex;
  List<TopicGrowthInsight> get dashboardGrowingTopicsOpenAlex =>
      _dashboardGrowingTopicsOpenAlex;
  List<OpenAlexRankedEntity> get dashboardRankedAuthors =>
      _dashboardTopAuthorsOpenAlex;
  List<OpenAlexRankedEntity> get dashboardRankedJournals =>
      _dashboardTopJournalsOpenAlex;
  List<Publication> get dashboardTopPapersOpenAlex =>
      _dashboardTopPapersOpenAlex;
  List<OpenAlexRankedEntity> get dashboardTopInstitutions =>
      _dashboardTopInstitutionsOpenAlex;
  List<OpenAlexRankedEntity> get dashboardWorksByType =>
      _dashboardWorksByTypeOpenAlex;
  List<OpenAlexRankedEntity> get dashboardTopAuthorsByCitations =>
      _dashboardTopAuthorsByCitationsOpenAlex;
  List<OpenAlexRankedEntity> get dashboardTopInstitutionsByCitations =>
      _dashboardTopInstitutionsByCitationsOpenAlex;
  List<OpenAlexRankedEntity> get dashboardTopAuthorsByHIndex =>
      _dashboardTopAuthorsByHIndexOpenAlex;
  List<OpenAlexRankedEntity> get dashboardCountries =>
      _dashboardCountriesOpenAlex;
  List<OpenAlexImpactProfile> get dashboardAuthorImpactProfiles =>
      _dashboardAuthorImpactProfilesOpenAlex;
  int get dashboardOpenAccessCount => _dashboardOpenAccessCount;
  int get dashboardClosedAccessCount => _dashboardClosedAccessCount;
  double get dashboardOpenAccessPercent {
    final total = _dashboardOpenAccessCount + _dashboardClosedAccessCount;
    if (total <= 0) return 0;
    return _dashboardOpenAccessCount / total * 100;
  }

  LandscapePulse get dashboardLandscapePulse =>
      ResearchInsights.buildLandscapePulse(
        totalPublications: _dashboardTotalOnOpenAlex,
        volumeByYear: _dashboardYearlyTrendFromOpenAlex,
        averageCitations: _dashboardAverageCitationOpenAlex,
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

  OpenAlexRankedEntity? dashboardRankedConceptById(String id) {
    for (final area in _dashboardTopResearchAreasOpenAlex) {
      if (area.id == id) return area;
    }
    for (final topic in _dashboardGrowingTopicsOpenAlex) {
      if (topic.id == id) {
        return OpenAlexRankedEntity(
          id: topic.id,
          name: topic.name,
          count: 0,
        );
      }
    }
    return null;
  }

  OpenAlexRankedEntity? dashboardRankedAuthorByName(String name) {
    for (final author in _dashboardTopAuthorsOpenAlex) {
      if (author.name == name) return author;
    }
    return null;
  }

  OpenAlexRankedEntity? dashboardRankedJournalByName(String name) {
    for (final journal in _dashboardTopJournalsOpenAlex) {
      if (journal.name == name) return journal;
    }
    return null;
  }

  /// Mß╗ƒ app / "Back to global overview" ΓÇö load dashboard to├án cß╗Ñc
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
      _snapshotDashboardFromActive();
    } catch (e) {
      _clearAllData();
      _clearDashboardMetrics();
      errorMessage = _mapError(e);
    } finally {
      isDashboardLoading = false;
      isTrendLoading = false;
      notifyListeners();
    }
  }

  /// User bß║Ñm search tr├¬n Explore ΓÇö 2 phase: b├ái tr╞░ß╗¢c, metrics sau
  Future<void> searchPublications(String topic) async {
    final generation = ++_searchGeneration;
    final trimmed = topic.trim();
    if (trimmed.isEmpty) return;

    recentSearches = await _recentSearchesService.add(trimmed);
    await AnalyticsService.logSearchTopic(trimmed);

    isSearchLoading = true;
    scope = AnalysisScope.topic;
    currentTopic = trimmed;
    errorMessage = null;
    searchListPage = 0;
    searchHasMore = false;
    publications = [];
    _clearTopicMetrics(); // x├│a sß╗æ global c┼⌐ ─æß╗â kh├┤ng hiß╗çn 937K nhß║ºm
    notifyListeners();

    try {
      // Phase 1: 20 b├ái relevance (giß╗æng OpenAlex web)
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
    // Phase 2: trend, top author/journal ΓÇö kh├┤ng chß║╖n danh s├ích b├ái
    _loadSearchMetricsInBackground(trimmed, generation);
  }

  /// ─Éß╗ìc recent searches tß╗½ SharedPreferences (tab Home).
  Future<void> loadRecentSearches() async {
    recentSearches = await _recentSearchesService.load();
    notifyListeners();
  }

  /// X├│a to├án bß╗Ö lß╗ïch sß╗¡ search.
  Future<void> clearRecentSearches() async {
    recentSearches = await _recentSearchesService.clear();
    notifyListeners();
  }

  /// Gß╗ìi nß╗ün sau khi 20 b├ái ─æ├ú hiß╗çn ΓÇö isTrendLoading = true trong l├║c chß╗¥
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

  /// true khi topic snapshot (Growth, MomentumΓÇª) ─æ├ú load xong
  bool get isTopicInsightsReady => !isGlobalScope && !isTrendLoading;

  /// Cuß╗Ön Explore ΓÇö load trang search tiß║┐p theo (+20 b├ái).
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
  // Delegate load* ΓÇö m├án detail gß╗ìi qua ─æ├óy, tß╗▒ gß║»n search/global filter
  // ---------------------------------------------------------------------------

  /// Pull-to-refresh ΓÇö reload dashboard hoß║╖c search hiß╗çn tß║íi.
  Future<void> refreshCurrentAnalysis() async {
    if (isGlobalScope) {
      await loadDefaultDashboard();
    } else {
      await searchPublications(currentTopic);
    }
  }

  /// YearDetailScreen ΓÇö b├ái cß╗ºa 1 n─âm (scoped search nß║┐u c├│).
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

  /// YearDetail ΓÇö ph├ón trang b├ái theo n─âm.
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

  /// Hot topics chips tr├¬n YearDetail.
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

  /// DetailScreen ΓÇö related works tß╗½ OpenAlex.
  Future<List<Publication>> loadRelatedWorks(Publication publication) {
    return _openAlexService.fetchRelatedWorks(
      relatedWorkIds: publication.relatedWorkIds,
      excludeWorkId: publication.id,
    );
  }

  /// DomainDetail ΓÇö trend chart cß╗ºa concept.
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

  /// DomainDetail ΓÇö top authors trong concept.
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

  /// DomainDetail ΓÇö top journals trong concept.
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

  /// DomainDetail ΓÇö papers paginated (gß╗ìi tß╗½ _load / _loadMorePapers).
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

  /// AuthorDetail ΓÇö trend theo n─âm.
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

  /// AuthorDetail ΓÇö top journals cß╗ºa author.
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

  /// JournalDetail ΓÇö trend theo n─âm.
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

  /// JournalDetail ΓÇö top authors tr├¬n journal.
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

  Future<OpenAlexWorksResult> loadWorksByInstitutionPage(
    OpenAlexRankedEntity institution,
    int page,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchWorksByInstitutionIdPage(
        institutionId: institution.id,
        page: page,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchWorksByInstitutionIdPage(
      institutionId: institution.id,
      page: page,
      search: currentTopic,
    );
  }

  Future<Map<int, int>> loadInstitutionTrend(OpenAlexRankedEntity institution) {
    if (isGlobalScope) {
      return _openAlexService.fetchInstitutionYearlyTrend(
        institutionId: institution.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchInstitutionYearlyTrend(
      institutionId: institution.id,
      search: currentTopic,
    );
  }

  Future<List<OpenAlexRankedEntity>> loadInstitutionTopAuthors(
    OpenAlexRankedEntity institution,
  ) {
    if (isGlobalScope) {
      return _openAlexService.fetchInstitutionTopAuthors(
        institutionId: institution.id,
        globalInfluential: true,
      );
    }
    return _openAlexService.fetchInstitutionTopAuthors(
      institutionId: institution.id,
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

  void _snapshotDashboardFromActive() {
    _dashboardTotalOnOpenAlex = totalOnOpenAlex;
    _dashboardYearlyTrendFromOpenAlex =
        Map<int, int>.from(yearlyTrendFromOpenAlex);
    _dashboardMonthlyTrendFromOpenAlex =
        Map<int, int>.from(monthlyTrendFromOpenAlex);
    _dashboardCitationsByYearOpenAlex =
        Map<int, int>.from(citationsByYearOpenAlex);
    _dashboardTopAuthorsOpenAlex = List<OpenAlexRankedEntity>.from(
      topAuthorsOpenAlex,
    );
    _dashboardTopJournalsOpenAlex = List<OpenAlexRankedEntity>.from(
      topJournalsOpenAlex,
    );
    _dashboardTopResearchAreasOpenAlex = List<OpenAlexRankedEntity>.from(
      topResearchAreasOpenAlex,
    );
    _dashboardTopInstitutionsOpenAlex = List<OpenAlexRankedEntity>.from(
      topInstitutionsOpenAlex,
    );
    _dashboardWorksByTypeOpenAlex = List<OpenAlexRankedEntity>.from(
      worksByTypeOpenAlex,
    );
    _dashboardTopAuthorsByCitationsOpenAlex =
        List<OpenAlexRankedEntity>.from(topAuthorsByCitationsOpenAlex);
    _dashboardTopInstitutionsByCitationsOpenAlex =
        List<OpenAlexRankedEntity>.from(topInstitutionsByCitationsOpenAlex);
    _dashboardTopAuthorsByHIndexOpenAlex =
        List<OpenAlexRankedEntity>.from(topAuthorsByHIndexOpenAlex);
    _dashboardCountriesOpenAlex =
        List<OpenAlexRankedEntity>.from(countriesOpenAlex);
    _dashboardAuthorImpactProfilesOpenAlex =
        List<OpenAlexImpactProfile>.from(authorImpactProfilesOpenAlex);
    _dashboardOpenAccessCount = openAccessCountOpenAlex;
    _dashboardClosedAccessCount = closedAccessCountOpenAlex;
    _dashboardGrowingTopicsOpenAlex = List<TopicGrowthInsight>.from(
      growingTopicsOpenAlex,
    );
    _dashboardTopPapersOpenAlex = List<Publication>.from(topPapersOpenAlex);
    _dashboardAverageCitationOpenAlex = averageCitationOpenAlex;
  }

  void _clearDashboardMetrics() {
    _dashboardTotalOnOpenAlex = 0;
    _dashboardYearlyTrendFromOpenAlex = {};
    _dashboardMonthlyTrendFromOpenAlex = {};
    _dashboardCitationsByYearOpenAlex = {};
    _dashboardTopAuthorsOpenAlex = [];
    _dashboardTopJournalsOpenAlex = [];
    _dashboardTopResearchAreasOpenAlex = [];
    _dashboardTopInstitutionsOpenAlex = [];
    _dashboardWorksByTypeOpenAlex = [];
    _dashboardTopAuthorsByCitationsOpenAlex = [];
    _dashboardTopInstitutionsByCitationsOpenAlex = [];
    _dashboardTopAuthorsByHIndexOpenAlex = [];
    _dashboardCountriesOpenAlex = [];
    _dashboardAuthorImpactProfilesOpenAlex = [];
    _dashboardOpenAccessCount = 0;
    _dashboardClosedAccessCount = 0;
    _dashboardGrowingTopicsOpenAlex = [];
    _dashboardTopPapersOpenAlex = [];
    _dashboardAverageCitationOpenAlex = 0;
  }

  /// X├│a metrics topic khi search mß╗¢i ΓÇö tr├ính hiß╗çn sß╗æ global c┼⌐.
  void _clearTopicMetrics() {
    topPapersOpenAlex = [];
    yearlyTrendFromOpenAlex = {};
    monthlyTrendFromOpenAlex = {};
    citationsByYearOpenAlex = {};
    avgCitationsByYearOpenAlex = {};
    topAuthorsOpenAlex = [];
    topJournalsOpenAlex = [];
    topResearchAreasOpenAlex = [];
    topInstitutionsOpenAlex = [];
    worksByTypeOpenAlex = [];
    topAuthorsByCitationsOpenAlex = [];
    topInstitutionsByCitationsOpenAlex = [];
    topAuthorsByHIndexOpenAlex = [];
    countriesOpenAlex = [];
    authorImpactProfilesOpenAlex = [];
    openAccessCountOpenAlex = 0;
    closedAccessCountOpenAlex = 0;
    growingTopicsOpenAlex = [];
    averageCitationOpenAlex = 0;
    totalOnOpenAlex = 0;
  }

  /// Reset to├án bß╗Ö state khi lß╗ùi nß║╖ng.
  void _clearAllData() {
    publications = [];
    _clearTopicMetrics();
    searchHasMore = false;
    searchListPage = 0;
  }

  /// OpenAlexException ΓåÆ string hiß╗ân thß╗ï ErrorBanner.
  String _mapError(Object e) {
    return e is OpenAlexException
        ? e.message
        : e.toString().replaceFirst('Exception: ', '');
  }

  /// Gom metrics OpenAlex ΓÇö c├íc request ─æß╗Öc lß║¡p chß║íy song song.
  Future<void> _loadAllOpenAlexMetrics({
    String? search,
    bool globalInfluential = false,
  }) async {
    isTrendLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _tryAggregate(
        () => _openAlexService.fetchPublicationTrendByYear(
          search: search,
          globalInfluential: globalInfluential,
        ),
        <int, int>{},
      ),
      _tryAggregate(
        () => _openAlexService.fetchWorksGroupedCounts(
          groupBy: OpenAlexService.groupByAuthor,
          search: search,
          globalInfluential: globalInfluential,
        ),
        <OpenAlexRankedEntity>[],
      ),
      _tryAggregate(
        () => _openAlexService.fetchWorksGroupedCounts(
          groupBy: OpenAlexService.groupByJournal,
          search: search,
          globalInfluential: globalInfluential,
        ),
        <OpenAlexRankedEntity>[],
      ),
      _tryAggregate(
        () => _openAlexService.fetchWorksGroupedCounts(
          groupBy: OpenAlexService.groupByConcept,
          search: search,
          globalInfluential: globalInfluential,
          limit: 8,
        ),
        <OpenAlexRankedEntity>[],
      ),
      _tryAggregate(
        () => _openAlexService.fetchTopPapers(
          search: search,
          globalInfluential: globalInfluential,
          limit: 10,
        ),
        <Publication>[],
      ),
      _tryAggregate(
        () => _openAlexService.fetchAverageCitation(
          search: search,
          globalInfluential: globalInfluential,
        ),
        0.0,
      ),
      _tryAggregate(
        () => _openAlexService.fetchCitationMetricsByYear(
          search: search,
          globalInfluential: globalInfluential,
        ),
        (totals: <int, int>{}, averages: <int, int>{}),
      ),
      _tryAggregate(
        () => _openAlexService.fetchWorksGroupedCounts(
          groupBy: OpenAlexService.groupByInstitution,
          search: search,
          globalInfluential: globalInfluential,
          limit: 5,
        ),
        <OpenAlexRankedEntity>[],
      ),
      _tryAggregate(
        () => _openAlexService.fetchWorksGroupedCounts(
          groupBy: OpenAlexService.groupByType,
          search: search,
          globalInfluential: globalInfluential,
          limit: 6,
        ),
        <OpenAlexRankedEntity>[],
      ),
      _tryAggregate(
        () => _openAlexService.fetchOpenAccessBreakdown(
          search: search,
          globalInfluential: globalInfluential,
        ),
        (openCount: 0, closedCount: 0),
      ),
      _tryAggregate(
        () => _openAlexService.fetchCountryDistribution(
          search: search,
          globalInfluential: globalInfluential,
        ),
        <OpenAlexRankedEntity>[],
      ),
    ]);

    yearlyTrendFromOpenAlex = results[0] as Map<int, int>;
    topAuthorsOpenAlex = results[1] as List<OpenAlexRankedEntity>;
    topJournalsOpenAlex = results[2] as List<OpenAlexRankedEntity>;
    topResearchAreasOpenAlex = results[3] as List<OpenAlexRankedEntity>;
    topPapersOpenAlex = results[4] as List<Publication>;
    averageCitationOpenAlex = results[5] as double;

    final citationMetrics = results[6] as ({
      Map<int, int> totals,
      Map<int, int> averages,
    });
    citationsByYearOpenAlex = citationMetrics.totals;
    avgCitationsByYearOpenAlex = citationMetrics.averages;

    topInstitutionsOpenAlex = results[7] as List<OpenAlexRankedEntity>;
    worksByTypeOpenAlex = results[8] as List<OpenAlexRankedEntity>;
    final openAccess = results[9] as ({int openCount, int closedCount});
    openAccessCountOpenAlex = openAccess.openCount;
    closedAccessCountOpenAlex = openAccess.closedCount;
    countriesOpenAlex = results[10] as List<OpenAlexRankedEntity>;

    await _loadImpactMetrics(
      search: search,
      globalInfluential: globalInfluential,
    );

    monthlyTrendFromOpenAlex = await _tryAggregate(
      () => _openAlexService.fetchPublicationTrendByMonth(
        year: DateTime.now().year,
        search: search,
        globalInfluential: globalInfluential,
      ),
      <int, int>{},
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

    isTrendLoading = false;
    notifyListeners();
  }

  List<String> _impactTopicIdsForSearch(String? search) {
    if (search == null || search.trim().isEmpty) return const [];
    return topResearchAreasOpenAlex
        .take(3)
        .map((topic) => topic.id)
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Impact charts cß║ºn topic id tß╗½ works search ΓÇö load sau khi c├│ top topics.
  Future<void> _loadImpactMetrics({
    String? search,
    bool globalInfluential = false,
  }) async {
    final topicIds = _impactTopicIdsForSearch(search);
    final results = await Future.wait([
      _tryAggregate(
        () => _openAlexService.fetchTopAuthorsByCitations(
          search: search,
          globalInfluential: globalInfluential,
          topicIds: topicIds.isEmpty ? null : topicIds,
        ),
        <OpenAlexRankedEntity>[],
      ),
      _tryAggregate(
        () => _openAlexService.fetchTopInstitutionsByCitations(
          search: search,
          globalInfluential: globalInfluential,
          topicIds: topicIds.isEmpty ? null : topicIds,
        ),
        <OpenAlexRankedEntity>[],
      ),
      _tryAggregate(
        () => _openAlexService.fetchTopAuthorsByHIndex(
          search: search,
          globalInfluential: globalInfluential,
          topicIds: topicIds.isEmpty ? null : topicIds,
        ),
        <OpenAlexRankedEntity>[],
      ),
      _tryAggregate(
        () => _openAlexService.fetchAuthorImpactProfiles(
          search: search,
          globalInfluential: globalInfluential,
          topicIds: topicIds.isEmpty ? null : topicIds,
        ),
        <OpenAlexImpactProfile>[],
      ),
    ]);

    topAuthorsByCitationsOpenAlex = results[0] as List<OpenAlexRankedEntity>;
    topInstitutionsByCitationsOpenAlex =
        results[1] as List<OpenAlexRankedEntity>;
    topAuthorsByHIndexOpenAlex = results[2] as List<OpenAlexRankedEntity>;
    authorImpactProfilesOpenAlex =
        results[3] as List<OpenAlexImpactProfile>;
  }

  /// Mß╗Öt API lß╗ùi kh├┤ng l├ám crash cß║ú dashboard ΓÇö trß║ú fallback rß╗ùng/0
  Future<T> _tryAggregate<T>(Future<T> Function() load, T fallback) async {
    try {
      return await load();
    } catch (_) {
      return fallback;
    }
  }
}
