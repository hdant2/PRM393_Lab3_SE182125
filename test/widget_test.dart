// Smoke test — MainShell 3 tab: Overview / Explore / About

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lab2/services/openalex_config.dart';
import 'package:lab2/theme/app_theme.dart';
<<<<<<< HEAD
import 'package:lab2/providers/app_navigation_provider.dart';
import 'package:lab2/providers/publication_provider.dart';
import 'package:lab2/screens/main_shell.dart';
import 'package:lab2/services/openalex_config.dart';

void main() {
  testWidgets('JournalAI shell smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = OpenAlexConfig();
    await config.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OpenAlexConfig>.value(value: config),
          ChangeNotifierProvider(
            create: (_) => PublicationProvider(config: config),
          ),
          ChangeNotifierProvider(create: (_) => AppNavigationProvider()),
=======
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
>>>>>>> feature/lab3
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

<<<<<<< HEAD
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('About'), findsWidgets);
    expect(find.text('Analytics'), findsNothing);
=======
    expect(find.text('JournalAI'), findsWidgets);
>>>>>>> feature/lab3
  });
}
