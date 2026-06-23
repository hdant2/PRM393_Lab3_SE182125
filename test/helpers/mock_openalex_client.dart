import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _mockAuthorResults = [
  {
    'id': 'https://openalex.org/A1',
    'display_name': 'Alice',
    'works_count': 120,
    'cited_by_count': 5400,
    'summary_stats': {'h_index': 42},
  },
  {
    'id': 'https://openalex.org/A2',
    'display_name': 'Bob',
    'works_count': 80,
    'cited_by_count': 3100,
    'summary_stats': {'h_index': 35},
  },
];

/// Returns canned OpenAlex JSON for common query shapes used in unit tests.
http.Client buildOpenAlexMockClient({Map<String, http.Response>? overrides}) {
  return MockClient((request) async {
    final override = overrides?[request.url.toString()];
    if (override != null) return override;

    final path = request.url.path;
    final groupBy = request.url.queryParameters['group_by'];
    final filter = request.url.queryParameters['filter'] ?? '';

    if (path.endsWith('/authors') || path.endsWith('/institutions')) {
      final filter = request.url.queryParameters['filter'] ?? '';
      if (filter.contains('topics.id')) {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 'https://openalex.org/A10',
                'display_name': 'Alice Researcher',
                'works_count': 120,
                'cited_by_count': 5400,
                'summary_stats': {'h_index': 42},
              },
              {
                'id': 'https://openalex.org/A11',
                'display_name': 'Bob Scientist',
                'works_count': 80,
                'cited_by_count': 3100,
                'summary_stats': {'h_index': 35},
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({'results': _mockAuthorResults}),
        200,
      );
    }

    if (filter.contains('from_publication_date')) {
      final monthMatch = RegExp(
        r'from_publication_date:\d{4}-(\d{2})',
      ).firstMatch(filter);
      final month = monthMatch != null ? int.parse(monthMatch.group(1)!) : 1;
      return http.Response(
        jsonEncode({'meta': {'count': month * 100}, 'results': []}),
        200,
      );
    }

    if (filter.contains('open_access.is_oa:true')) {
      return http.Response(
        jsonEncode({'meta': {'count': 60}, 'results': []}),
        200,
      );
    }

    if (filter.contains('open_access.is_oa:false')) {
      return http.Response(
        jsonEncode({'meta': {'count': 40}, 'results': []}),
        200,
      );
    }

    if (groupBy == 'open_access.is_oa') {
      return http.Response(
        jsonEncode({
          'group_by': [
            {'key': true, 'count': 60},
            {'key': false, 'count': 40},
          ],
        }),
        200,
      );
    }

    if (groupBy == 'type') {
      return http.Response(
        jsonEncode({
          'group_by': [
            {
              'key': 'article',
              'key_display_name': 'article',
              'count': 80,
            },
            {
              'key': 'review',
              'key_display_name': 'review',
              'count': 20,
            },
          ],
        }),
        200,
      );
    }

    if (groupBy == 'publication_year') {
      return http.Response(
        jsonEncode({
          'group_by': [
            {'key': '2023', 'count': 25},
            {'key': '2024', 'count': 30},
          ],
        }),
        200,
      );
    }

    if (groupBy == 'authorships.countries') {
      return http.Response(
        jsonEncode({
          'group_by': [
            {
              'key': 'US',
              'key_display_name': 'United States',
              'count': 45,
            },
            {
              'key': 'CN',
              'key_display_name': 'China',
              'count': 30,
            },
          ],
        }),
        200,
      );
    }

    if (groupBy != null) {
      return http.Response(
        jsonEncode({
          'group_by': [
            {
              'key': 'https://openalex.org/A1',
              'key_display_name': 'Alice',
              'count': 10,
            },
          ],
        }),
        200,
      );
    }

    if (request.url.queryParameters['select'] == 'cited_by_count') {
      final filter = request.url.queryParameters['filter'] ?? '';
      final yearMatch = RegExp(r'publication_year:(\d{4})').firstMatch(filter);
      final year = yearMatch != null ? int.parse(yearMatch.group(1)!) : 2024;
      final volume = year == 2023 ? 25 : 30;
      return http.Response(
        jsonEncode({
          'meta': {'count': volume},
          'results': [
            {'cited_by_count': 10},
            {'cited_by_count': 30},
          ],
        }),
        200,
      );
    }

    return http.Response(
      jsonEncode({
        'meta': {'count': 100},
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
}
