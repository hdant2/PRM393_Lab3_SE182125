import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/app_navigation_viewmodel.dart';
import '../viewmodels/publication_viewmodel.dart';
import 'overview_screen.dart';
import 'journals_tab_screen.dart';
import 'keywords_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _pages = [
    OverviewScreen(),
    JournalsTabScreen(),
    KeywordsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PublicationViewModel>();
      if (!provider.hasData && !provider.isDashboardLoading) {
        provider.loadDefaultDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<AppNavigationViewModel>();

    return Scaffold(
      body: IndexedStack(
        index: nav.tabIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.tabIndex,
        onDestinationSelected: (index) {
          context.read<AppNavigationViewModel>().goToTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Journals',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Keywords',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
