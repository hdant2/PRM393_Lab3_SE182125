import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:lab2/main.dart' as app;

void main() {
  patrolTest(
    'TC01: Google Sign-In',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      expect($(const Text('Welcome to JournalAI')), findsOneWidget);
      expect($(const Text('Sign in with Google')), findsOneWidget);

      await $(const Text('Sign in with Google')).tap();
      await $.pumpAndSettle();

      expect($(const Text('JournalAI')), findsWidgets);
    },
  );

  patrolTest(
    'TC02: Topic Search',
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
    'TC03: Publication Details',
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
