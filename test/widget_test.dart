import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lab2/theme/app_theme.dart';
import 'package:lab2/providers/app_navigation_provider.dart';
import 'package:lab2/providers/publication_provider.dart';
import 'package:lab2/screens/main_shell.dart';

void main() {
  testWidgets('JournalAI shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PublicationProvider()),
          ChangeNotifierProvider(create: (_) => AppNavigationProvider()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const MainShell(),
        ),
      ),
    );

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('JournalAI'), findsWidgets);
  });
}
