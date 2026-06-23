import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab2/models/openalex_ranked_entity.dart';
import 'package:lab2/services/openalex_config.dart';
import 'package:lab2/services/openalex_exception.dart';
import 'package:lab2/services/openalex_service.dart';

void main() {
  OpenAlexService fastService(http.Client client) {
    return OpenAlexService(
      OpenAlexConfig(),
      httpClient: client,
      maxRetries: 1,
      retryBackoffMs: 0,
      requestTimeout: const Duration(milliseconds: 50),
    );
  }

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
        expect(request.url.queryParameters['filter'], contains('2000'));
        return http.Response(
          jsonEncode({
            'group_by': [
              {'key': '1998', 'count': 5},
              {'key': '2022', 'count': 15},
              {'key': '2023', 'count': 25},
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final trend = await service.fetchPublicationTrendByYear(search: 'ai');

      expect(trend.containsKey(1998), isFalse);
      expect(trend[2022], 15);
      expect(trend[2023], 25);
    });

    test('fetchPublicationTrendByYear keeps year filter for global dashboard', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['filter'], contains('2000'));
        expect(request.url.queryParameters['filter'], contains('cited_by_count'));
        return http.Response(
          jsonEncode({'group_by': []}),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      await service.fetchPublicationTrendByYear(globalInfluential: true);
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

    test('fetchOpenAccessBreakdown counts via is_oa filters', () async {
      final client = MockClient((request) async {
        final filter = request.url.queryParameters['filter'] ?? '';
        if (filter.contains('open_access.is_oa:true')) {
          return http.Response(
            jsonEncode({'meta': {'count': 420000}, 'results': []}),
            200,
          );
        }
        if (filter.contains('open_access.is_oa:false')) {
          return http.Response(
            jsonEncode({'meta': {'count': 502700}, 'results': []}),
            200,
          );
        }
        fail('Unexpected filter: $filter');
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final breakdown = await service.fetchOpenAccessBreakdown(
        globalInfluential: true,
      );

      expect(breakdown.openCount, 420000);
      expect(breakdown.closedCount, 502700);
    });

    test('fetchPublicationTrendByMonth counts each month in year', () async {
      final client = MockClient((request) async {
        final filter = request.url.queryParameters['filter'] ?? '';
        expect(filter, contains('from_publication_date'));
        final monthMatch = RegExp(
          r'from_publication_date:\d{4}-(\d{2})',
        ).firstMatch(filter);
        final month = int.parse(monthMatch!.group(1)!);
        return http.Response(
          jsonEncode({'meta': {'count': month * 10}, 'results': []}),
          200,
        );
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final trend = await service.fetchPublicationTrendByMonth(
        year: DateTime.now().year,
        globalInfluential: true,
      );

      expect(trend.isNotEmpty, isTrue);
      expect(trend[1], 10);
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

    test('fetchConceptsForYear uses topic group_by', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['group_by'], OpenAlexService.groupByTopic);
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
        if (request.url.queryParameters['group_by'] == 'publication_year') {
          return http.Response(
            jsonEncode({
              'group_by': [
                {'key': '2024', 'count': 3},
              ],
            }),
            200,
          );
        }
        if (request.url.queryParameters['select'] == 'cited_by_count') {
          return http.Response(
            jsonEncode({
              'meta': {'count': 3},
              'results': [
                {'cited_by_count': 10},
                {'cited_by_count': 30},
                {'cited_by_count': 20},
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'meta': {'count': 0}, 'results': []}), 200);
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final metrics = await service.fetchCitationMetricsByYear(search: 'ai');

      expect(metrics.totals[2024], 60);
      expect(metrics.averages[2024], 20);
    });

    test('fetchCitationMetricsByYear extrapolates when sample is smaller than volume',
        () async {
      final client = MockClient((request) async {
        if (request.url.queryParameters['group_by'] == 'publication_year') {
          return http.Response(
            jsonEncode({
              'group_by': [
                {'key': '2023', 'count': 10},
              ],
            }),
            200,
          );
        }
        if (request.url.queryParameters['select'] == 'cited_by_count') {
          return http.Response(
            jsonEncode({
              'meta': {'count': 10},
              'results': [
                {'cited_by_count': 5},
                {'cited_by_count': 15},
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'meta': {'count': 0}, 'results': []}), 200);
      });

      final service = OpenAlexService(OpenAlexConfig(), httpClient: client);
      final metrics = await service.fetchCitationMetricsByYear(search: 'ml');

      expect(metrics.totals[2023], 100);
      expect(metrics.averages[2023], 10);
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

      final service = OpenAlexService(
        OpenAlexConfig(),
        httpClient: client,
        maxRetries: 2,
        retryBackoffMs: 0,
      );
      final count = await service.fetchWorksTotalCount(search: 'retry');

      expect(count, 7);
      expect(attempts, 2);
    });

    test('recovers after socket failure', () async {
      var attempts = 0;
      final client = MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          throw const SocketException('offline');
        }
        return http.Response(
          jsonEncode({'meta': {'count': 3}, 'results': []}),
          200,
        );
      });

      final service = OpenAlexService(
        OpenAlexConfig(),
        httpClient: client,
        maxRetries: 2,
        retryBackoffMs: 0,
      );
      final count = await service.fetchWorksTotalCount(search: 'socket');

      expect(count, 3);
      expect(attempts, 2);
    });

    test('maps exhausted socket failures to OpenAlexException', () async {
      final client = MockClient((request) async {
        throw const SocketException('offline');
      });

      final service = fastService(client);

      expect(
        () => service.fetchWorksTotalCount(search: 'offline'),
        throwsA(
          isA<OpenAlexException>().having(
            (error) => error.message,
            'message',
            contains('Khong ket noi'),
          ),
        ),
      );
    });

    test('maps client exceptions to OpenAlexException', () async {
      final client = MockClient((request) async {
        throw http.ClientException('broken pipe');
      });

      final service = fastService(client);

      expect(
        () => service.fetchWorksTotalCount(search: 'client'),
        throwsA(
          isA<OpenAlexException>().having(
            (error) => error.message,
            'message',
            contains('Loi mang'),
          ),
        ),
      );
    });

    test('maps server busy responses after retries', () async {
      final client = MockClient((request) async {
        return http.Response('busy', 503);
      });

      final service = fastService(client);

      expect(
        () => service.fetchWorksTotalCount(search: 'busy'),
        throwsA(
          isA<OpenAlexException>().having(
            (error) => error.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('fetchTopicGrowthInsights ranks concept growth', () async {
      final client = MockClient((request) async {
        if (request.url.queryParameters['group_by'] == 'publication_year') {
          return http.Response(
            jsonEncode({
              'group_by': [
                {'key': '2020', 'count': 10},
                {'key': '2024', 'count': 30},
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'group_by': []}), 200);
      });

      final service = fastService(client);
      final insights = await service.fetchTopicGrowthInsights(
        concepts: const [
          OpenAlexRankedEntity(id: 'C1', name: 'AI', count: 10),
        ],
        search: 'ai',
      );

      expect(insights, isNotEmpty);
      expect(insights.first.name, 'AI');
      expect(insights.first.growthPercent, greaterThan(0));
    });
  });
}
