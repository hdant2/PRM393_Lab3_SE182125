import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab2/services/openalex_config.dart';
import 'package:lab2/services/openalex_service.dart';

void main() {
  group('OpenAlexService static helpers', () {
    test('shortOpenAlexId extracts trailing id', () {
      expect(
        OpenAlexService.shortOpenAlexId('https://openalex.org/W123456789'),
        'W123456789',
      );
      expect(OpenAlexService.shortOpenAlexId('W999'), 'W999');
    });

    test('parseGroupByYear ignores invalid years', () {
      final trend = OpenAlexService.parseGroupByYear({
        'group_by': [
          {'key': '2022', 'count': 10},
          {'key': 'invalid', 'count': 5},
        ],
      });

      expect(trend, {2022: 10});
    });

    test('parseGroupByNamedCounts sorts and limits results', () {
      final ranked = OpenAlexService.parseGroupByNamedCounts(
        {
          'group_by': [
            {
              'key': 'https://openalex.org/J1',
              'key_display_name': 'Small',
              'count': 2,
            },
            {
              'key': 'https://openalex.org/J2',
              'key_display_name': 'Large',
              'count': 20,
            },
          ],
        },
        limit: 1,
      );

      expect(ranked, hasLength(1));
      expect(ranked.first.name, 'Large');
    });

    test('parseOpenAccessGroupBy reads boolean keys', () {
      final breakdown = OpenAlexService.parseOpenAccessGroupBy({
        'group_by': [
          {'key': true, 'count': 101800},
          {'key': false, 'count': 100700},
        ],
      });

      expect(breakdown.openCount, 101800);
      expect(breakdown.closedCount, 100700);
    });

    test('parseOpenAccessGroupBy handles string and numeric keys', () {
      final breakdown = OpenAlexService.parseOpenAccessGroupBy({
        'group_by': [
          {'key': '1', 'key_display_name': 'true', 'count': 55},
          {'key': '0', 'key_display_name': 'false', 'count': 45},
        ],
      });

      expect(breakdown.openCount, 55);
      expect(breakdown.closedCount, 45);
    });

    test('parseEntityImpactProfiles maps author stats', () {
      final profiles = OpenAlexService.parseEntityImpactProfiles({
        'results': [
          {
            'id': 'https://openalex.org/A1',
            'display_name': 'Alice',
            'works_count': 50,
            'cited_by_count': 1200,
            'summary_stats': {'h_index': 18},
          },
        ],
      });

      expect(profiles, hasLength(1));
      expect(profiles.first.name, 'Alice');
      expect(profiles.first.worksCount, 50);
      expect(profiles.first.citedByCount, 1200);
      expect(profiles.first.hIndex, 18);
    });

    test('topicIds filter is not passed as author name search', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/authors');
        expect(request.url.queryParameters.containsKey('search'), isFalse);
        expect(
          request.url.queryParameters['filter'],
          contains('topics.id:T1'),
        );
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 'https://openalex.org/A1',
                'display_name': 'Alice',
                'works_count': 10,
                'cited_by_count': 500,
                'summary_stats': {'h_index': 12},
              },
              {
                'id': 'https://openalex.org/A2',
                'display_name': 'Bob',
                'works_count': 8,
                'cited_by_count': 300,
                'summary_stats': {'h_index': 9},
              },
            ],
          }),
          200,
        );
      });

      final service = OpenAlexService(
        OpenAlexConfig(),
        httpClient: client,
        maxRetries: 1,
        retryBackoffMs: 0,
      );

      final ranked = await service.fetchTopAuthorsByCitations(
        topicIds: const ['T1'],
      );

      expect(ranked, hasLength(2));
      expect(ranked.first.count, 500);
    });
  });
}
