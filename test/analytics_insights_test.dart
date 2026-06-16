import 'package:flutter_test/flutter_test.dart';
import 'package:lab2/utils/publication_analytics.dart';
import 'package:lab2/utils/research_insights.dart';
import 'package:lab2/models/openalex_ranked_entity.dart';
import 'package:lab2/models/publication.dart';
import 'package:lab2/models/publication_author.dart';

void main() {
  final sample = [
    Publication(
      id: '1',
      title: 'Paper A',
      year: 2020,
      citations: 100,
      journal: 'Nature',
      doi: '',
      authorEntries: const [PublicationAuthor(id: 'A1', name: 'Alice')],
      abstractText: '',
      concepts: ['AI', 'ML'],
    ),
    Publication(
      id: '2',
      title: 'Paper B',
      year: 2021,
      citations: 50,
      journal: 'IEEE',
      doi: '',
      authorEntries: const [PublicationAuthor(id: 'A2', name: 'Bob')],
      abstractText: '',
      concepts: ['AI'],
    ),
  ];

  test('PublicationAnalytics computes rankings and averages', () {
    expect(PublicationAnalytics.averageCitation(sample), 75);
    expect(PublicationAnalytics.topResearchAreas(sample).first.key, 'AI');
    expect(PublicationAnalytics.topJournals(sample).first.key, 'Nature');
    expect(PublicationAnalytics.mostActiveYear(sample), '2020');
  });

  test('ResearchInsights helper copy methods', () {
    final authors = [
      const OpenAlexRankedEntity(id: 'A1', name: 'Alice', count: 10),
    ];
    final journals = [
      const OpenAlexRankedEntity(id: 'J1', name: 'Nature', count: 5),
    ];

    expect(
      ResearchInsights.researchLeadersInsight(authors),
      contains('Alice'),
    );
    expect(
      ResearchInsights.journalPowerInsight(journals),
      contains('Nature'),
    );
  });
}
