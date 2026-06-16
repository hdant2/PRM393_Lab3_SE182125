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

import 'providers/app_navigation_provider.dart';
import 'providers/publication_provider.dart';
import 'screens/splash_screen.dart';
import 'services/openalex_config.dart';
import 'theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    // MultiProvider = "kho chung" state cho cả app, mọi màn hình đọc được
    return MultiProvider(
      providers: [
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
