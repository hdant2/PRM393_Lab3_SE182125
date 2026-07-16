// Splash: preload dashboard → chuyển MainShell (4 tab Home/Journal/Keywords/Profile)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/publication_viewmodel.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'main_shell.dart';

/// Màn mở đầu — loadDefaultDashboard() rồi pushReplacement MainShell
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  /// Preload data trước khi user thấy tab Home
  Future<void> _bootstrap() async {
    final provider = context.read<PublicationViewModel>();
    await provider.loadDefaultDashboard();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(size: 88),
            SizedBox(height: 20),
            Text(
              'JournalAI',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Research Intelligence',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppColors.surfaceMuted,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading research data...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
