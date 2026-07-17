import 'package:flutter/material.dart';

// [Merge resolved] Chọn feature/lab3: AppNavigationViewModel thay vì AppNavigationProvider
class AppNavigationViewModel extends ChangeNotifier {
  int tabIndex = 0;

  void goToTab(int index) {
    tabIndex = index;
    notifyListeners(); // MainShell rebuild → IndexedStack đổi tab
  }
}
