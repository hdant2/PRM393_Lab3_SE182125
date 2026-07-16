import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:lab2/main.dart' as app;

void main() {
  patrolTest(
    'TC06: Keywords Navigation',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      await $(const Text('Keywords')).tap();
      await $.pumpAndSettle();

      expect($(const Text('Keywords')), findsWidgets);
    },
  );

  patrolTest(
    'TC07: Keyword Details',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      await $(const Text('Keywords')).tap();
      await $.pumpAndSettle();

      final keywordTile = $(ListTile);
      if (keywordTile.exists) {
        await keywordTile.first.tap();
        await $.pumpAndSettle();

        expect($(Icons.arrow_back), findsOneWidget);
      }
    },
  );
}
