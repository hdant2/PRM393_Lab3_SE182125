import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:lab2/services/openalex_exception.dart';
import 'package:lab2/services/openalex_service.dart';

void main() {
  group('OpenAlexService error mapping', () {
    test('OpenAlexException stores friendly message', () {
      final error = OpenAlexException('Server busy', statusCode: 503);
      expect(error.toString(), 'Server busy');
      expect(error.statusCode, 503);
    });
  });

  group('OpenAlexService live API', () {
    const apiKey = String.fromEnvironment('OPENALEX_API_KEY');

    test(
      'searchPublications returns results when OpenAlex is available',
      () async {
        if (apiKey.isEmpty) {
          return;
        }

        final service = OpenAlexService();

        try {
          final result = await service
              .searchPublications('machine learning')
              .timeout(const Duration(seconds: 60));

          expect(result.publications, isNotEmpty);
          expect(result.publications.first.title, isNotEmpty);
          expect(result.totalOnOpenAlex, greaterThan(result.publications.length));
        } on OpenAlexException catch (e) {
          if (e.statusCode == 502 || e.statusCode == 503 || e.statusCode == 429) {
            markTestSkipped('OpenAlex tạm bận (${e.statusCode}): ${e.message}');
          }
          rethrow;
        } on TimeoutException {
          markTestSkipped('OpenAlex không phản hồi trong 25s — thử lại sau.');
        }
      },
      skip: apiKey.isEmpty ? 'Set OPENALEX_API_KEY via --dart-define-from-file' : false,
    );
  });
}
