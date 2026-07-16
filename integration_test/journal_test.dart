import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:lab2/main.dart' as app;

void main() {
  patrolTest(
    'TC04: Journals Navigation',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      await $(const Text('Journals')).tap();
      await $.pumpAndSettle();

      expect($(const Text('Journals')), findsWidgets);
    },
  );

  patrolTest(
    'TC05: Journal Details',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      await $(const Text('Journals')).tap();
      await $.pumpAndSettle();

      final journalTile = $(ListTile);
      if (journalTile.exists) {
        await journalTile.first.tap();
        await $.pumpAndSettle();

        expect($(Icons.arrow_back), findsOneWidget);
      }
    },
  );
}
