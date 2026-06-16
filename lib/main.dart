import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_navigation_provider.dart';
import 'providers/publication_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PublicationProvider()),
        ChangeNotifierProvider(create: (_) => AppNavigationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JournalAI',
        theme: buildAppTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
