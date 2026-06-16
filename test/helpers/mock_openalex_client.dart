import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Returns canned OpenAlex JSON for common query shapes used in unit tests.
http.Client buildOpenAlexMockClient({Map<String, http.Response>? overrides}) {
  return MockClient((request) async {
    final override = overrides?[request.url.toString()];
    if (override != null) return override;

    final groupBy = request.url.queryParameters['group_by'];
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
