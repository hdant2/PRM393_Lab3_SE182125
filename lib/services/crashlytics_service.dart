import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  static void init() {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  static Future<void> generateHandledException() async {
    try {
      throw Exception('This is a handled test exception from JournalAI');
    } catch (exception, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        reason: 'Handled exception test',
      );
    }
  }

  static void generateTestCrash() {
    FirebaseCrashlytics.instance.crash();
  }
}
