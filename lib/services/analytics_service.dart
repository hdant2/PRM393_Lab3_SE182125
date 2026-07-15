import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;

  static FirebaseAnalytics get _instance {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics!;
  }

  static FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(
      analytics: _instance,
    );
  }

  static Future<void> logLogin() async {
    try {
      await _instance.logLogin(loginMethod: 'google');
    } catch (_) {}
  }

  static Future<void> logLogout() async {
    try {
      await _instance.logEvent(name: 'logout');
    } catch (_) {}
  }

  static Future<void> logSearchTopic(String keyword) async {
    try {
      await _instance.logEvent(
        name: 'search_topic',
        parameters: {'keyword': keyword},
      );
    } catch (_) {}
  }

  static Future<void> logViewPublication({
    required String title,
    required int year,
  }) async {
    try {
      await _instance.logEvent(
        name: 'view_publication',
        parameters: {
          'publication_title': title,
          'publication_year': year,
        },
      );
    } catch (_) {}
  }

  static Future<void> logViewJournal(String journalName) async {
    try {
      await _instance.logEvent(
        name: 'view_journal',
        parameters: {'journal_name': journalName},
      );
    } catch (_) {}
  }

  static Future<void> logViewKeyword(String keyword) async {
    try {
      await _instance.logEvent(
        name: 'view_keyword',
        parameters: {'keyword': keyword},
      );
    } catch (_) {}
  }

  static Future<void> logViewAuthor({required String authorName}) async {
    try {
      await _instance.logEvent(
        name: 'view_author',
        parameters: {'author_name': authorName},
      );
    } catch (_) {}
  }

  static Future<void> logExportPdf(String topic) async {
    try {
      await _instance.logEvent(
        name: 'export_pdf',
        parameters: {'topic': topic},
      );
    } catch (_) {}
  }

  static Future<void> logOpenPaper({required String title}) async {
    try {
      await _instance.logEvent(
        name: 'open_paper',
        parameters: {
          'title': title.length > 100 ? title.substring(0, 100) : title,
        },
      );
    } catch (_) {}
  }

  static Future<void> logOpenDoi({required String doi}) async {
    try {
      await _instance.logEvent(
        name: 'open_doi',
        parameters: {'doi': doi},
      );
    } catch (_) {}
  }

  static Future<void> logLoadMorePapers({
    required String source,
    required int currentCount,
  }) async {
    try {
      await _instance.logEvent(
        name: 'load_more_papers',
        parameters: {
          'source': source,
          'current_count': currentCount,
        },
      );
    } catch (_) {}
  }
}
