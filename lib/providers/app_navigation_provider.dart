import 'package:flutter/material.dart';

/// Quản lý tab bottom navigation (0=Overview, 1=Explore, 2=About).
/// Tách riêng khỏi PublicationProvider vì chỉ là UI state, không liên quan API.
class AppNavigationProvider extends ChangeNotifier {
  int tabIndex = 0;

  void goToTab(int index) {
    tabIndex = index;
    notifyListeners(); // MainShell rebuild → IndexedStack đổi tab
  }
}
