import 'package:flutter/material.dart';

class AppNavigationProvider extends ChangeNotifier {
  int tabIndex = 0;

  void goToTab(int index) {
    tabIndex = index;
    notifyListeners();
  }
}
