// Test ResearchInsights — growth %, momentum, concept growth

import 'package:flutter_test/flutter_test.dart';

import 'package:lab2/models/research_insight.dart';
import 'package:lab2/utils/research_insights.dart';
import 'package:lab2/models/openalex_ranked_entity.dart';
import 'package:lab2/models/publication.dart';

void main() {
  test('analyzeTrend computes growth and momentum', () {
    final insight = ResearchInsights.analyzeTrend(
      volumeByYear: {
        2019: 100,
        2020: 120,
        2021: 150,
        2022: 180,
        2023: 220,
        2024: 300,
      },
      topicLabel: 'Artificial Intelligence',
    );

    expect(insight.periodGrowthPercent, 200);
    expect(insight.peakYear, 2024);
    expect(insight.momentum, isNot(MomentumLevel.declining));
    expect(insight.headline, contains('Artificial Intelligence'));
  });

  test('computeConceptGrowth compares early and late periods', () {
    final growth = ResearchInsights.computeConceptGrowth({
      2018: 10,
      2019: 12,
      2020: 14,
      2021: 40,
      2022: 50,
      2023: 60,
    });

    expect(growth, greaterThan(100));
  });

  test('formatGrowth renders signed percentage', () {
    expect(ResearchInsights.formatGrowth(25), '+25%');
    expect(ResearchInsights.formatGrowth(-4.2), '-4%');
  });

  test('analyzeTrend returns empty insight for insufficient data', () {
    expect(
      ResearchInsights.analyzeTrend(volumeByYear: {2024: 10}),
      TrendInsight.empty,
    );
  });

  test('analyzeTrend notes citation divergence when volume outpaces citations', () {
    final insight = ResearchInsights.analyzeTrend(
      volumeByYear: {2020: 100, 2024: 200},
      citationsByYear: {2020: 500, 2024: 400},
      topicLabel: 'Topic',
    );

    expect(insight.citationNote, contains('citation'));
  });

  test('influentialPapersInsight handles empty and landmark papers', () {
    expect(
      ResearchInsights.influentialPapersInsight([]),
      contains('will appear'),
    );

    final papers = [
      Publication(
        id: 'W1',
        title: 'Breakthrough',
        year: 2020,
        citations: 60000,
        journal: 'Nature',
        doi: '',
        authorEntries: const [],
        abstractText: '',
        concepts: const [],
      ),
    ];

    expect(
      ResearchInsights.influentialPapersInsight(papers),
      contains('Landmark'),
    );
  });

  test('journalPowerInsight handles single and multiple journals', () {
    expect(
      ResearchInsights.journalPowerInsight([]),
      contains('Top publishing venues'),
    );
    expect(
      ResearchInsights.journalPowerInsight([
        const OpenAlexRankedEntity(id: 'J1', name: 'Nature', count: 10),
      ]),
      contains('dominant'),
    );
    expect(
      ResearchInsights.journalPowerInsight([
        const OpenAlexRankedEntity(id: 'J1', name: 'Nature', count: 10),
        const OpenAlexRankedEntity(id: 'J2', name: 'Science', count: 8),
      ]),
      contains('Nature'),
    );
  });

  test('buildLandscapePulse and buildTopicSnapshot expose dashboard fields', () {
    final pulse = ResearchInsights.buildLandscapePulse(
      totalPublications: 1000,
      volumeByYear: {2022: 100, 2023: 150},
      averageCitations: 12.5,
    );
    expect(pulse.totalPublications, 1000);
    expect(pulse.peakYear, 2023);

    final snapshot = ResearchInsights.buildTopicSnapshot(
      topic: 'AI',
      totalPublications: 500,
      volumeByYear: {2022: 10, 2023: 20},
      citationsByYear: {2022: 100, 2023: 120},
      topJournal: const OpenAlexRankedEntity(id: 'J1', name: 'Nature', count: 1),
    );

    expect(snapshot.topic, 'AI');
    expect(snapshot.topJournal, 'Nature');
  });
}
