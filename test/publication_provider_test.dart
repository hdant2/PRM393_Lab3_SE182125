import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab2/models/openalex_ranked_entity.dart';
import 'package:lab2/models/publication.dart';
import 'package:lab2/models/publication_author.dart';
import 'package:lab2/models/research_insight.dart';
import 'package:lab2/providers/publication_provider.dart';
import 'package:lab2/services/openalex_config.dart';
import 'package:lab2/services/openalex_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_openalex_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PublicationProvider computed values', () {
    late PublicationProvider provider;

    setUp(() {
      provider = PublicationProvider(config: OpenAlexConfig());
    });

    test('trendInsight uses loaded yearly data', () {
      provider.yearlyTrendFromOpenAlex = {
        2020: 10,
        2021: 20,
        2022: 40,
      };
      provider.scope = AnalysisScope.topic;
      provider.currentTopic = 'Machine Learning';

      final insight = provider.trendInsight;

      expect(insight.peakYear, 2022);
      expect(insight.headline, contains('Machine Learning'));
    });

    test('topicSnapshot is null in global scope', () {
      provider.scope = AnalysisScope.global;
      provider.currentTopic = PublicationProvider.globalTopicLabel;

      expect(provider.topicSnapshot, isNull);
    });

    test('topicSnapshot is populated in topic scope', () {
      provider.scope = AnalysisScope.topic;
      provider.currentTopic = 'ras';
      provider.totalOnOpenAlex = 500;
      provider.yearlyTrendFromOpenAlex = {2022: 10, 2023: 20};

      final snapshot = provider.topicSnapshot;

      expect(snapshot, isNotNull);
      expect(snapshot!.topic, 'ras');
      expect(snapshot.totalPublications, 500);
    });

    test('landscapePulse uses dashboard totals', () {
      provider.totalOnOpenAlex = 1000;
      provider.yearlyTrendFromOpenAlex = {2022: 100, 2023: 150};
      provider.averageCitationOpenAlex = 12.5;

      final pulse = provider.landscapePulse;

      expect(pulse.peakYear, 2023);
      expect(pulse.yoyGrowthPercent, greaterThan(0));
    });

    test('insight getters and lookup helpers', () {
      provider.topPapersOpenAlex = [
        Publication(
          id: 'W1',
          title: 'Landmark',
          year: 2020,
          citations: 60000,
          journal: 'Nature',
          doi: '',
          authorEntries: const [],
          abstractText: '',
          concepts: const [],
        ),
      ];
      provider.topAuthorsOpenAlex = [
        const OpenAlexRankedEntity(id: 'A1', name: 'Alice', count: 50),
      ];
      provider.topJournalsOpenAlex = [
        const OpenAlexRankedEntity(id: 'J1', name: 'Nature', count: 20),
        const OpenAlexRankedEntity(id: 'J2', name: 'Science', count: 15),
      ];
      provider.yearlyTrendFromOpenAlex = {2024: 500, 2023: 300};
      provider.totalOnOpenAlex = 1200;

      expect(provider.influentialPapersInsight, contains('Landmark'));
      expect(provider.researchLeadersInsight, contains('Alice'));
      expect(provider.journalPowerInsight, contains('Nature'));
      expect(provider.mostActiveYearLabel, contains('2024'));
      expect(provider.formattedTotalOnOpenAlex, '1.2K');
      expect(provider.rankedAuthorByName('Alice')?.count, 50);
      expect(provider.rankedJournalByName('Science')?.count, 15);
      expect(provider.openAlexCountForYear(2024), 500);
      expect(provider.hasData, isTrue);
    });

    test('rankedConceptById resolves research areas and growth topics', () {
      provider.topResearchAreasOpenAlex = [
        const OpenAlexRankedEntity(id: 'C1', name: 'AI', count: 8),
      ];
      provider.growingTopicsOpenAlex = [
        const TopicGrowthInsight(
          id: 'C2',
          name: 'Robotics',
          growthPercent: 40,
        ),
      ];

      expect(provider.rankedConceptById('C1')?.name, 'AI');
      expect(provider.rankedConceptById('C2')?.name, 'Robotics');
      expect(provider.rankedConceptById('missing'), isNull);
    });
  });

  group('PublicationProvider with mocked OpenAlex', () {
    late PublicationProvider provider;

    setUp(() {
      final client = buildOpenAlexMockClient();
      provider = PublicationProvider(
        config: OpenAlexConfig(),
        openAlexService: OpenAlexService(OpenAlexConfig(), httpClient: client),
      );
    });

    test('searchPublications loads first page and background metrics', () async {
      await provider.searchPublications('machine learning');

      expect(provider.scope, AnalysisScope.topic);
      expect(provider.currentTopic, 'machine learning');
      expect(provider.publications, isNotEmpty);
      expect(provider.totalOnOpenAlex, 100);
      expect(provider.isSearchLoading, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.yearlyTrendFromOpenAlex, isNotEmpty);
      expect(provider.topAuthorsOpenAlex, isNotEmpty);
      expect(provider.isTrendLoading, isFalse);
      expect(provider.isTopicInsightsReady, isTrue);
    });

    test('loadMoreSearchPublications appends next page', () async {
      await provider.searchPublications('ai');
      final initialCount = provider.publications.length;

      await provider.loadMoreSearchPublications();

      expect(provider.publications.length, greaterThan(initialCount));
      expect(provider.isLoadingMorePublications, isFalse);
    });

    test('loadPublicationsForYear delegates to service', () async {
      provider.scope = AnalysisScope.topic;
      provider.currentTopic = 'ras';

      final papers = await provider.loadPublicationsForYear(2024);

      expect(papers.single.title, 'Sample paper');
    });

    test('loadWorksByAuthor and loadWorksByJournal return publications', () async {
      const author = OpenAlexRankedEntity(id: 'A1', name: 'Alice', count: 1);
      const journal = OpenAlexRankedEntity(id: 'J1', name: 'Nature', count: 1);

      final authorPapers = await provider.loadWorksByAuthor(author);
      final journalPapers = await provider.loadWorksByJournal(journal);

      expect(authorPapers, isNotEmpty);
      expect(journalPapers, isNotEmpty);
    });

    test('loadRelatedWorks excludes current publication id', () async {
      final publication = Publication(
        id: 'https://openalex.org/W1',
        title: 'Current',
        year: 2024,
        citations: 1,
        journal: 'Nature',
        doi: '',
        authorEntries: const [],
        abstractText: '',
        concepts: const [],
        relatedWorkIds: const ['https://openalex.org/W1', 'https://openalex.org/W2'],
      );

      final related = await provider.loadRelatedWorks(publication);

      expect(related.every((paper) => paper.id != publication.id), isTrue);
    });

    test('loadConceptTrend returns yearly counts', () async {
      const concept = OpenAlexRankedEntity(id: 'C1', name: 'AI', count: 1);

      final trend = await provider.loadConceptTrend(concept);

      expect(trend[2023], 25);
      expect(trend[2024], 30);
    });

    test('searchPublications ignores blank query', () async {
      await provider.searchPublications('   ');

      expect(provider.publications, isEmpty);
      expect(provider.isSearchLoading, isFalse);
    });

    test('maps HTTP errors to errorMessage', () async {
      final failingClient = MockClient((request) async {
        return http.Response('forbidden', 403);
      });
      final failingProvider = PublicationProvider(
        config: OpenAlexConfig(),
        openAlexService: OpenAlexService(
          OpenAlexConfig(),
          httpClient: failingClient,
        ),
      );

      await failingProvider.searchPublications('blocked');

      expect(failingProvider.errorMessage, isNotNull);
      expect(failingProvider.publications, isEmpty);
    });
  });
}
