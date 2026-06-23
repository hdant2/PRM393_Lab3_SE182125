// =============================================================================
// main_shell.dart — KHUNG CHÍNH (3 TAB)
// =============================================================================
// Overview | Explore | About — trend analytics nằm trong Explore sau search
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_navigation_provider.dart';
import '../providers/publication_provider.dart';
import 'about_screen.dart';
import 'overview_screen.dart';
import 'search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _pages = [
    OverviewScreen(),
    SearchScreen(),
    AboutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PublicationProvider>();
      if (!provider.hasDashboardData && !provider.isDashboardLoading) {
        provider.loadDefaultDashboard();
      }
      provider.loadRecentSearches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<AppNavigationProvider>();

    return Scaffold(
      body: IndexedStack(
        index: nav.tabIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.tabIndex,
        onDestinationSelected: (index) {
          context.read<AppNavigationProvider>().goToTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
