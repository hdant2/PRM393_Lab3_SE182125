import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:lab2/main.dart' as app;

void main() {
  patrolTest(
    'TC08: Profile Navigation',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      await $(const Text('Profile')).tap();
      await $.pumpAndSettle();

      expect($(const Text('Profile')), findsWidgets);
      expect($(const Text('Sign Out')), findsOneWidget);
    },
  );

  patrolTest(
    'TC09: PDF Export',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      await $(const Text('Profile')).tap();
      await $.pumpAndSettle();

      await $(const Text('Export & Upload Report')).tap();
      await $.pumpAndSettle();

      await $.pump(const Duration(seconds: 5));
    },
  );

  patrolTest(
    'TC10: Remote Config',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      await $(const Text('Profile')).tap();
      await $.pumpAndSettle();

      await $(const Text('Firebase Remote Config')).tap();
      await $.pumpAndSettle();

      expect($(const Text('Max Journals Displayed')), findsOneWidget);
      expect($(const Text('Max Keywords Displayed')), findsOneWidget);
    },
  );

  patrolTest(
    'TC11: Logout',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      await $(const Text('Profile')).tap();
      await $.pumpAndSettle();

      await $(const Text('Sign Out')).tap();
      await $.pumpAndSettle();

      expect($(const Text('Sign in with Google')), findsOneWidget);
    },
  );
}
