// Test ResearchInsights — growth %, momentum, concept growth

import 'package:flutter_test/flutter_test.dart';

import 'package:lab2/models/research_insight.dart';
import 'package:lab2/utils/research_insights.dart';

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
}
