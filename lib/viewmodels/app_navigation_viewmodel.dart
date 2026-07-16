import 'package:flutter/material.dart';

<<<<<<< HEAD:lib/providers/app_navigation_provider.dart
/// Quản lý tab bottom navigation (0=Overview, 1=Explore, 2=About).
/// Tách riêng khỏi PublicationProvider vì chỉ là UI state, không liên quan API.
class AppNavigationProvider extends ChangeNotifier {
=======
class AppNavigationViewModel extends ChangeNotifier {
>>>>>>> feature/lab3:lib/viewmodels/app_navigation_viewmodel.dart
  int tabIndex = 0;

  void goToTab(int index) {
    tabIndex = index;
    notifyListeners(); // MainShell rebuild → IndexedStack đổi tab
  }
}
