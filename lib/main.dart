import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/publication_provider.dart';
import 'screens/search_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        // Đăng ký PublicationProvider
        ChangeNotifierProvider(
          create: (_) => PublicationProvider(),
        ),

      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Journal Trend Analyzer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const SearchScreen(),
      ),
    );
  }
}