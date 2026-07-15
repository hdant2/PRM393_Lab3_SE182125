import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lab2/theme/app_theme.dart';
import 'package:lab2/viewmodels/app_navigation_viewmodel.dart';
import 'package:lab2/viewmodels/publication_viewmodel.dart';
import 'package:lab2/screens/overview_screen.dart';
import 'package:lab2/screens/journals_tab_screen.dart';
import 'package:lab2/screens/keywords_screen.dart';

void main() {
  testWidgets('JournalAI shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PublicationViewModel()),
          ChangeNotifierProvider(create: (_) => AppNavigationViewModel()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: IndexedStack(
              index: 0,
              children: const [
                OverviewScreen(),
                JournalsTabScreen(),
                KeywordsScreen(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('JournalAI'), findsWidgets);
  });
}
