// Test Publication.fromJson — map JSON OpenAlex → model

import 'package:flutter_test/flutter_test.dart';

import 'package:lab2/models/publication.dart';

void main() {
  group('Publication.fromJson', () {
    test('parses basic fields', () {
      final publication = Publication.fromJson({
        'id': 'https://openalex.org/W123',
        'title': 'Machine Learning Survey',
        'publication_year': 2022,
        'cited_by_count': 42,
        'type': 'article',
        'doi': 'https://doi.org/10.1000/test',
        'primary_location': {
          'source': {'display_name': 'Nature AI'},
          'landing_page_url': 'https://publisher.example/paper',
        },
        'best_oa_location': {
          'landing_page_url': 'https://oa.example/paper',
        },
        'authorships': [
          {
            'author': {
              'id': 'https://openalex.org/A1',
              'display_name': 'Jane Doe',
            },
          },
        ],
        'abstract_inverted_index': {
          'Hello': [0],
          'world': [1],
        },
        'related_works': [
          'https://openalex.org/W999',
        ],
      });

      expect(publication.id, 'https://openalex.org/W123');
      expect(publication.title, 'Machine Learning Survey');
      expect(publication.year, 2022);
      expect(publication.citations, 42);
      expect(publication.journal, 'Nature AI');
      expect(publication.authors, ['Jane Doe']);
      expect(publication.authorEntries.first.id, 'https://openalex.org/A1');
      expect(publication.abstractText, 'Hello world');
      expect(publication.displayDoi, '10.1000/test');
      expect(publication.readUrl, 'https://oa.example/paper');
      expect(publication.landingPageUrl, 'https://publisher.example/paper');
      expect(publication.relatedWorkIds, ['https://openalex.org/W999']);
      expect(publication.workType, 'Article');
    });

    test('uses defaults when fields are missing', () {
      final publication = Publication.fromJson({});

      expect(publication.title, 'No Title');
      expect(publication.year, 0);
      expect(publication.citations, 0);
      expect(publication.journal, 'Unknown Journal');
      expect(publication.authors, isEmpty);
      expect(publication.abstractText, 'No abstract available');
      expect(publication.hasDoi, isFalse);
      expect(publication.hasReadLink, isFalse);
    });
  });
}
