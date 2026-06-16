import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab2/models/publication.dart';
import 'package:lab2/models/publication_author.dart';
import 'package:lab2/models/research_insight.dart';
import 'package:lab2/widgets/entity_detail_sections.dart';

void main() {
  testWidgets('EntityStatsCard renders publication metrics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EntityStatsCard(
            totalCount: 1200,
            avgCitations: 15.4,
            loadedCount: 20,
          ),
        ),
      ),
    );

    expect(find.text('Publications'), findsOneWidget);
    expect(find.text('1.2K'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('EntityGrowthInsightCard shows growth label', (tester) async {
    const insight = TrendInsight(
      periodGrowthPercent: 25,
      yoyGrowthPercent: 10,
      avgAnnualGrowthPercent: 8,
      peakYear: 2024,
      startYear: 2020,
      endYear: 2024,
      momentum: MomentumLevel.medium,
      headline: 'Growing topic',
      summary: 'Summary',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EntityGrowthInsightCard(insight: insight),
        ),
      ),
    );

    expect(find.text('+25%'), findsOneWidget);
    expect(find.text('Publication growth'), findsOneWidget);
  });

  testWidgets('EntityDetailErrorView triggers retry callback', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntityDetailErrorView(
            message: 'Network error',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Network error'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('EntityTrendSection shows empty message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EntityTrendSection(
            title: 'Trend',
            subtitle: 'Publications by year',
            trend: {},
            emptyMessage: 'No trend yet',
          ),
        ),
      ),
    );

    expect(find.text('No trend yet'), findsOneWidget);
  });

  testWidgets('EntityTrendSection renders chart when data exists', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: EntityTrendSection(
              title: 'Trend',
              subtitle: 'Publications by year',
              trend: {2022: 10, 2023: 20},
              emptyMessage: 'No trend yet',
            ),
          ),
        ),
      ),
    );

    expect(find.text('No trend yet'), findsNothing);
    expect(find.text('Trend'), findsOneWidget);
  });

  testWidgets('EntityPapersSection shows papers and load more', (tester) async {
    var loadedMore = false;
    final paper = Publication(
      id: 'W1',
      title: 'Sample paper',
      year: 2024,
      citations: 12,
      journal: 'Nature',
      doi: '',
      authorEntries: const [PublicationAuthor(id: 'A1', name: 'Alice')],
      abstractText: '',
      concepts: const ['AI'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntityPapersSection(
            title: 'Papers',
            subtitle: 'Most cited',
            papers: [paper],
            totalCount: 50,
            isLoadingMore: false,
            hasMore: true,
            onLoadMore: () => loadedMore = true,
            emptyMessage: 'No papers',
          ),
        ),
      ),
    );

    expect(find.text('Sample paper'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    expect(loadedMore, isTrue);
  });
}