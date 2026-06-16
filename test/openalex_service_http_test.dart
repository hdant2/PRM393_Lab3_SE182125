import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab2/services/openalex_config.dart';
import 'package:lab2/services/openalex_service.dart';

void main() {
  group('OpenAlexService HTTP', () {
    test('fetchWorksTotalCount parses meta count', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'api.openalex.org');
        return http.Response(
          jsonEncode({'meta': {'count': 42}, 'results': []}),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final count = await service.fetchWorksTotalCount(search: 'ras');

      expect(count, 42);
    });

    test('maps HTTP 401 to OpenAlexException', () async {
      final client = MockClient((request) async {
        return http.Response('unauthorized', 401);
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);

      expect(
        () => service.fetchWorksTotalCount(search: 'ras'),
        throwsA(isA<Exception>()),
      );
    });

    test('searchPublications maps work json to publications', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'meta': {'count': 1},
            'results': [
              {
                'id': 'https://openalex.org/W1',
                'title': 'Sample paper',
                'publication_year': 2024,
                'cited_by_count': 12,
                'type': 'article',
                'primary_location': {
                  'source': {'display_name': 'Nature'},
                },
                'authorships': [],
                'abstract_inverted_index': null,
              },
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final result = await service.searchPublications('ras');

      expect(result.totalOnOpenAlex, 1);
      expect(result.publications.single.title, 'Sample paper');
      expect(result.publications.single.citations, 12);
    });

    test('fetchSearchPage requests explicit page number', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['page'], '2');
        return http.Response(
          jsonEncode({'meta': {'count': 40}, 'results': []}),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final result = await service.fetchSearchPage('ai', page: 2);

      expect(result.totalOnOpenAlex, 40);
    });

    test('fetchPublicationTrendByYear parses group_by payload', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['group_by'], 'publication_year');
        return http.Response(
          jsonEncode({
            'group_by': [
              {'key': '2022', 'count': 15},
              {'key': '2023', 'count': 25},
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final trend = await service.fetchPublicationTrendByYear(search: 'ai');

      expect(trend[2022], 15);
      expect(trend[2023], 25);
    });

    test('fetchWorksGroupedCounts parses ranked entities', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['group_by'], isNotEmpty);
        return http.Response(
          jsonEncode({
            'group_by': [
              {
                'key': 'https://openalex.org/A1',
                'key_display_name': 'Alice',
                'count': 9,
              },
              {
                'key': 'https://openalex.org/A2',
                'key_display_name': 'Bob',
                'count': 21,
              },
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final ranked = await service.fetchWorksGroupedCounts(
        groupBy: OpenAlexService.groupByAuthor,
        search: 'ml',
        limit: 2,
      );

      expect(ranked.first.name, 'Bob');
      expect(ranked.first.count, 21);
    });

    test('fetchAverageCitation returns mean cited_by_count', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'meta': {'count': 2},
            'results': [
              {'cited_by_count': 10},
              {'cited_by_count': 30},
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final average = await service.fetchAverageCitation(search: 'ai');

      expect(average, 20);
    });

    test('fetchTopPapers returns parsed publications', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'meta': {'count': 1},
            'results': [
              {
                'id': 'https://openalex.org/W9',
                'title': 'Top paper',
                'publication_year': 2023,
                'cited_by_count': 500,
                'type': 'article',
                'primary_location': {
                  'source': {'display_name': 'Science'},
                },
                'authorships': [],
              },
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final papers = await service.fetchTopPapers(search: 'ai', limit: 1);

      expect(papers.single.title, 'Top paper');
      expect(papers.single.citations, 500);
    });

    test('fetchPublicationsForYear filters by year', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['filter'], contains('2022'));
        return http.Response(
          jsonEncode({
            'meta': {'count': 1},
            'results': [
              {
                'id': 'https://openalex.org/W2',
                'title': 'Year paper',
                'publication_year': 2022,
                'cited_by_count': 3,
                'type': 'article',
                'primary_location': {
                  'source': {'display_name': 'IEEE'},
                },
                'authorships': [],
              },
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final papers = await service.fetchPublicationsForYear(
        year: 2022,
        search: 'ai',
      );

      expect(papers.single.year, 2022);
    });

    test('fetchWorksByAuthorId applies author filter', () async {
      final client = MockClient((request) async {
        expect(
          request.url.queryParameters['filter'],
          contains('authorships.author.id'),
        );
        return http.Response(
          jsonEncode({'meta': {'count': 0}, 'results': []}),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final papers = await service.fetchWorksByAuthorId(
        authorId: 'https://openalex.org/A123',
        search: 'ml',
      );

      expect(papers, isEmpty);
    });

    test('fetchWorksBySourceId applies journal filter', () async {
      final client = MockClient((request) async {
        expect(
          request.url.queryParameters['filter'],
          contains('primary_location.source.id'),
        );
        return http.Response(
          jsonEncode({'meta': {'count': 0}, 'results': []}),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final papers = await service.fetchWorksBySourceId(
        sourceId: 'https://openalex.org/S123',
      );

      expect(papers, isEmpty);
    });

    test('fetchRelatedWorks resolves ids filter', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['filter'], contains('W2'));
        return http.Response(
          jsonEncode({
            'meta': {'count': 1},
            'results': [
              {
                'id': 'https://openalex.org/W2',
                'title': 'Related',
                'publication_year': 2021,
                'cited_by_count': 8,
                'type': 'article',
                'primary_location': {
                  'source': {'display_name': 'PLoS ONE'},
                },
                'authorships': [],
              },
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final related = await service.fetchRelatedWorks(
        relatedWorkIds: const ['https://openalex.org/W1', 'https://openalex.org/W2'],
        excludeWorkId: 'https://openalex.org/W1',
      );

      expect(related.single.id, 'https://openalex.org/W2');
    });

    test('fetchRelatedWorks returns empty for blank ids', () async {
      final client = MockClient((request) async {
        fail('Should not call HTTP when related ids are empty');
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final related = await service.fetchRelatedWorks(relatedWorkIds: const []);

      expect(related, isEmpty);
    });

    test('fetchConceptsForYear uses concept group_by', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['group_by'], OpenAlexService.groupByConcept);
        return http.Response(
          jsonEncode({
            'group_by': [
              {
                'key': 'https://openalex.org/C1',
                'key_display_name': 'Machine learning',
                'count': 4,
              },
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final concepts = await service.fetchConceptsForYear(
        year: 2023,
        search: 'ai',
      );

      expect(concepts.single.name, 'Machine learning');
    });

    test('fetchConceptYearlyTrend parses yearly counts', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'group_by': [
              {'key': '2020', 'count': 5},
              {'key': '2021', 'count': 8},
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final trend = await service.fetchConceptYearlyTrend(
        conceptId: 'https://openalex.org/C1',
        search: 'ai',
      );

      expect(trend[2020], 5);
      expect(trend[2021], 8);
    });

    test('fetchCitationMetricsByYear aggregates per-year citations', () async {
      final client = MockClient((request) async {
        if (request.url.queryParameters['select'] == 'cited_by_count') {
          return http.Response(
            jsonEncode({
              'meta': {'count': 2},
              'results': [
                {'cited_by_count': 10},
                {'cited_by_count': 30},
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'meta': {'count': 0}, 'results': []}), 200);
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final metrics = await service.fetchCitationMetricsByYear(search: 'ai');

      expect(metrics.totals.values, isNotEmpty);
      expect(metrics.averages.values, isNotEmpty);
    });

    test('retries transient HTTP 429 then succeeds', () async {
      var attempts = 0;
      final client = MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response('rate limited', 429);
        }
        return http.Response(
          jsonEncode({'meta': {'count': 7}, 'results': []}),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final count = await service.fetchWorksTotalCount(search: 'retry');

      expect(count, 7);
      expect(attempts, 2);
    });
  });
}
