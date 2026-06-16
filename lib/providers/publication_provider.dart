import 'package:flutter/material.dart';

import '../models/openalex_ranked_entity.dart';
import '../models/openalex_works_result.dart';
import '../models/publication.dart';
import '../models/research_insight.dart';
import '../services/openalex_exception.dart';
import '../services/openalex_service.dart';
import '../utils/count_format.dart';
import '../utils/research_insights.dart';

enum AnalysisScope { global, topic }

class PublicationProvider extends ChangeNotifier {
  final OpenAlexService _openAlexService = OpenAlexService();

  static const globalTopicLabel = 'Global Research Overview';

  AnalysisScope scope = AnalysisScope.global;
  String currentTopic = globalTopicLabel;
  List<Publication> publications = [];
  List<Publication> topPapersOpenAlex = [];
  Map<int, int> yearlyTrendFromOpenAlex = {};
  Map<int, int> citationsByYearOpenAlex = {};
  Map<int, int> avgCitationsByYearOpenAlex = {};
  List<OpenAlexRankedEntity> topAuthorsOpenAlex = [];
  List<OpenAlexRankedEntity> topJournalsOpenAlex = [];
  List<OpenAlexRankedEntity> topResearchAreasOpenAlex = [];
  List<TopicGrowthInsight> growingTopicsOpenAlex = [];
  double averageCitationOpenAlex = 0;
  int totalOnOpenAlex = 0;
  bool isDashboardLoading = false;
  bool isSearchLoading = false;
  bool isTrendLoading = false;
  bool isLoadingMorePublications = false;
  bool searchHasMore = false;
  int searchListPage = 0;
  String? errorMessage;

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

  Future<void> searchPublications(String topic) async {
    final generation = ++_searchGeneration;

    isSearchLoading = true;
    scope = AnalysisScope.topic;
    currentTopic = topic;
    errorMessage = null;
    searchListPage = 0;
    searchHasMore = false;
    publications = [];
    _clearTopicMetrics();
    notifyListeners();

    try {
      final works = await _openAlexService.searchPublications(topic);
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
    _loadSearchMetricsInBackground(topic, generation);
  }

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

  bool get isTopicInsightsReady => !isGlobalScope && !isTrendLoading;

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

  Future<void> refreshCurrentAnalysis() async {
    if (isGlobalScope) {
      await loadDefaultDashboard();
    } else {
      await searchPublications(currentTopic);
    }
  }

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

  Future<List<Publication>> loadRelatedWorks(Publication publication) {
    return _openAlexService.fetchRelatedWorks(
      relatedWorkIds: publication.relatedWorkIds,
      excludeWorkId: publication.id,
    );
  }

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

  void _clearAllData() {
    publications = [];
    _clearTopicMetrics();
    searchHasMore = false;
    searchListPage = 0;
  }

  String _mapError(Object e) {
    return e is OpenAlexException
        ? e.message
        : e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _loadAllOpenAlexMetrics({
    String? search,
    bool globalInfluential = false,
  }) async {
    isTrendLoading = true;
    notifyListeners();

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
    );

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

  Future<T> _tryAggregate<T>(Future<T> Function() load, T fallback) async {
    try {
      return await load();
    } catch (_) {
      return fallback;
    }
  }
}
