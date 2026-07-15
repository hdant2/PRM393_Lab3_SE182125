import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/crashlytics_service.dart';
import 'services/messaging_service.dart';

import 'viewmodels/app_navigation_viewmodel.dart';
import 'viewmodels/publication_viewmodel.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'screens/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('=== MAIN START ===');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _firebaseReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('=== INIT STATE ===');
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    debugPrint('=== FIREBASE INIT START ===');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 30));

      debugPrint('=== FIREBASE INIT DONE ===');

      try {
        CrashlyticsService.init();
      } catch (_) {}

      try {
        MessagingService.init();
      } catch (_) {}

      if (mounted) setState(() => _firebaseReady = true);
    } catch (e) {
      debugPrint('=== FIREBASE INIT ERROR: $e ===');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('=== BUILD: ready=$_firebaseReady, error=$_error ===');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PublicationViewModel()),
        ChangeNotifierProvider(create: (_) => AppNavigationViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JournalAI',
        theme: buildAppTheme(),
        home: _error != null
            ? Scaffold(
                body: Center(
                  child: Text('Firebase Error: $_error'),
                ),
              )
            : _firebaseReady
                ? const AuthGate()
                : const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Initializing...'),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
