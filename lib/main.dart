// =============================================================================
// main.dart — ĐIỂM VÀO CỦA APP
// =============================================================================
// Luồng khởi động:
//   1. main() chạy trước runApp → load API key từ SharedPreferences
//   2. MyApp bọc toàn app bằng Provider (quản lý state)
//   3. SplashScreen → MainShell (3 tab: Overview, Explore, About)
//
// Kiến trúc 3 tầng (nhớ câu này khi trả lời thầy):
//   screens/  → UI (chỉ hiển thị + gọi provider)
//   providers/ → state (danh sách bài, loading, search topic…)
//   services/  → gọi HTTP tới api.openalex.org
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

<<<<<<< HEAD
import 'providers/app_navigation_provider.dart';
import 'providers/publication_provider.dart';
import 'screens/splash_screen.dart';
import 'services/openalex_config.dart';
=======
import 'firebase_options.dart';
import 'services/crashlytics_service.dart';
import 'services/messaging_service.dart';
import 'services/remote_config_service.dart';
import 'services/openalex_config.dart';
import 'services/analytics_service.dart';
import 'viewmodels/app_navigation_viewmodel.dart';
import 'viewmodels/publication_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
>>>>>>> feature/lab3
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';

<<<<<<< HEAD
Future<void> main() async {
  // Bắt buộc trước runApp khi dùng async (SharedPreferences, v.v.)
  WidgetsFlutterBinding.ensureInitialized();

  // Tạo object lưu OpenAlex API key (About tab hoặc dart-define lúc build)
  final openAlexConfig = OpenAlexConfig();
  await openAlexConfig.load();

  runApp(MyApp(openAlexConfig: openAlexConfig));
}

class MyApp extends StatelessWidget {
  final OpenAlexConfig openAlexConfig;

  const MyApp({super.key, required this.openAlexConfig});
=======
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('=== MAIN START ===');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
>>>>>>> feature/lab3

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _appReady = false;
  final OpenAlexConfig _openAlexConfig = OpenAlexConfig();
  final AuthViewModel _authViewModel = AuthViewModel();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Khởi tạo Firebase (Auth, Analytics, FCM, Remote Config, Crashlytics).
  Future<void> _bootstrap() async {
    try {
      await _openAlexConfig.load();
    } catch (_) {}

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 20));
      try {
        CrashlyticsService.init();
      } catch (_) {}
      try {
        MessagingService.init();
      } catch (_) {}
      try {
        await RemoteConfigService.init();
      } catch (_) {}
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }

    await _authViewModel.bootstrap();

    if (mounted) setState(() => _appReady = true);
  }

  @override
  Widget build(BuildContext context) {
    // MultiProvider = "kho chung" state cho cả app, mọi màn hình đọc được
    return MultiProvider(
      providers: [
<<<<<<< HEAD
        // API key — About screen ghi, OpenAlexService đọc
        ChangeNotifierProvider<OpenAlexConfig>.value(value: openAlexConfig),

        // State chính: bài báo, trend, search, metrics OpenAlex
        ChangeNotifierProvider(
          create: (context) => PublicationProvider(
            config: context.read<OpenAlexConfig>(),
          ),
        ),

        // Tab bottom nav đang chọn tab nào (0–3)
        ChangeNotifierProvider(create: (_) => AppNavigationProvider()),
=======
        ChangeNotifierProvider.value(value: _openAlexConfig),
        ChangeNotifierProvider(
          create: (_) => PublicationViewModel(config: _openAlexConfig),
        ),
        ChangeNotifierProvider(create: (_) => AppNavigationViewModel()),
        ChangeNotifierProvider.value(value: _authViewModel),
>>>>>>> feature/lab3
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JournalAI',
        theme: buildAppTheme(),
        navigatorObservers: [AnalyticsService.getObserver()],
        home: !_appReady
            ? const Scaffold(
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
              )
            : const AuthGate(),
      ),
    );
  }
}
