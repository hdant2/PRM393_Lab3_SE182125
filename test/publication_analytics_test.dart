import 'package:flutter_test/flutter_test.dart';

import 'package:lab2/models/publication.dart';
import 'package:lab2/models/publication_author.dart';
import 'package:lab2/utils/publication_analytics.dart';

void main() {
  group('PublicationAnalytics', () {
    final sample = [
      Publication(
        id: '1',
        title: 'Paper A',
        year: 2020,
        citations: 100,
        journal: 'Nature',
        doi: '',
        authorEntries: const [
          PublicationAuthor(id: 'A1', name: 'Alice'),
          PublicationAuthor(id: 'A2', name: 'Bob'),
        ],
        abstractText: '',
        concepts: ['Artificial intelligence', 'Machine learning'],
      ),
      Publication(
        id: '2',
        title: 'Paper B',
        year: 2021,
        citations: 50,
        journal: 'Nature',
        doi: '',
        authorEntries: const [
          PublicationAuthor(id: 'A1', name: 'Alice'),
        ],
        abstractText: '',
        concepts: ['Artificial intelligence'],
      ),
      Publication(
        id: '3',
        title: 'Paper C',
        year: 2020,
        citations: 200,
        journal: 'IEEE Access',
        doi: '',
        authorEntries: const [
          PublicationAuthor(id: 'A3', name: 'Carol'),
        ],
        abstractText: '',
        concepts: ['Data science'],
      ),
    ];

    test('groups by year and ranks top entities', () {
      expect(PublicationAnalytics.groupByYear(sample), {2020: 2, 2021: 1});
      expect(PublicationAnalytics.topJournals(sample).first.key, 'Nature');
      expect(PublicationAnalytics.topAuthors(sample).first.key, 'Alice');
      expect(
        PublicationAnalytics.mostInfluentialPaper(sample).title,
        'Paper C',
      );
      expect(
        PublicationAnalytics.topResearchAreas(sample).first.key,
        'Artificial intelligence',
      );
    });
  });
}
