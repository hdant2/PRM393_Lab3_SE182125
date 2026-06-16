// Smoke test — MainShell 3 tab: Overview / Explore / About

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lab2/theme/app_theme.dart';
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
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const MainShell(),
        ),
      ),
    );

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('About'), findsWidgets);
    expect(find.text('Analytics'), findsNothing);
  });
}
