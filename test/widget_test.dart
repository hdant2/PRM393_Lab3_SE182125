// Smoke test — MainShell 3 tab: Overview / Explore / About

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lab2/services/openalex_config.dart';
import 'package:lab2/theme/app_theme.dart';
// [Merge resolved] Chọn feature/lab3: Sử dụng viewmodels thay vì providers
import 'package:lab2/viewmodels/app_navigation_viewmodel.dart';
import 'package:lab2/viewmodels/publication_viewmodel.dart';
import 'package:lab2/screens/overview_screen.dart';
import 'package:lab2/screens/journals_tab_screen.dart';
import 'package:lab2/screens/keywords_screen.dart';

void main() {
  testWidgets('JournalAI shell smoke test', (WidgetTester tester) async {
    final config = OpenAlexConfig();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => PublicationViewModel(config: config),
          ),
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

// [Merge resolved] Chọn feature/lab3: Kiểm tra 'JournalAI' thay vì 'Overview'/'Explore'/'About'
    expect(find.text('JournalAI'), findsWidgets);
  });
}
