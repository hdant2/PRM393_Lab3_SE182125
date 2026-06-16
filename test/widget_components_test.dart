import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab2/widgets/search_loading_view.dart';
import 'package:lab2/widgets/trend_chart.dart';

void main() {
  testWidgets('SearchLoadingView shows query text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SearchLoadingView(query: 'machine learning'),
      ),
    );

    expect(find.text('Searching "machine learning"'), findsOneWidget);
    expect(find.text('Fetching publications from OpenAlex'), findsOneWidget);
  });

  testWidgets('TrendChart renders empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrendChart(yearlyData: {}),
      ),
    );

    expect(find.text('No trend data available'), findsOneWidget);
  });

  testWidgets('TrendChart renders line chart for yearly data', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          height: 300,
          child: TrendChart(
            yearlyData: {
              2020: 10,
              2021: 20,
              2022: 30,
            },
          ),
        ),
      ),
    );

    expect(find.text('No trend data available'), findsNothing);
  });
}
