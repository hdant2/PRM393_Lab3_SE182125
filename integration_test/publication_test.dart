import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:lab2/main.dart' as app;

void main() {
  patrolTest(
    'TC14: Topic Search Flow',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      final searchField = $(TextField);
      if (searchField.exists) {
        await searchField.enterText('Artificial Intelligence');
        await $.pumpAndSettle();

        await $(Icons.arrow_forward).tap();
        await $.pumpAndSettle();

        expect($(const Text('Publications')), findsWidgets);
      }
    },
  );

  patrolTest(
    'TC15: Publication Details Flow',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      if ($(const Text('Sign in with Google')).exists) {
        await $(const Text('Sign in with Google')).tap();
        await $.pumpAndSettle();
      }

      final searchField = $(TextField);
      if (searchField.exists) {
        await searchField.enterText('Artificial Intelligence');
        await $.pumpAndSettle();

        await $(Icons.arrow_forward).tap();
        await $.pumpAndSettle();
      }

      final publicationCard = $(Card);
      if (publicationCard.exists) {
        await publicationCard.first.tap();
        await $.pumpAndSettle();

        expect($(Icons.arrow_back), findsOneWidget);
      }
    },
  );
}
