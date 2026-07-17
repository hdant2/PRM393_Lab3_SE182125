import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static bool _isReady = false;

  /// Gọi sau Firebase.initializeApp() trong _bootstrap()
  static void init() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _isReady = true;
    } catch (e) {
      // [Fix] Log lỗi thay vì nuốt im lặng — giúp debug khi Debug View không hiển thị event
      debugPrint('Analytics init error: $e');
    }
  }

  static FirebaseAnalytics? get _instance {
    if (!_isReady) return null;
    return _analytics;
  }

  static FirebaseAnalyticsObserver? getObserver() {
    final analytics = _instance;
    if (analytics == null) return null;
    return FirebaseAnalyticsObserver(analytics: analytics);
  }

  static Future<void> logLogin() async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logLogin(loginMethod: 'google');
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  static Future<void> logLogout() async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(name: 'logout');
    } catch (e) {
      debugPrint('Analytics logLogout error: $e');
    }
  }

  static Future<void> logSearchTopic(String keyword) async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(
        name: 'search_topic',
        parameters: {'keyword': keyword},
      );
    } catch (e) {
      debugPrint('Analytics logSearchTopic error: $e');
    }
  }

  static Future<void> logViewPublication({
    required String title,
    required int year,
  }) async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(
        name: 'view_publication',
        parameters: {
          'publication_title': title,
          'publication_year': year,
        },
      );
    } catch (e) {
      debugPrint('Analytics logViewPublication error: $e');
    }
  }

  static Future<void> logViewJournal(String journalName) async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(
        name: 'view_journal',
        parameters: {'journal_name': journalName},
      );
    } catch (e) {
      debugPrint('Analytics logViewJournal error: $e');
    }
  }

  static Future<void> logViewKeyword(String keyword) async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(
        name: 'view_keyword',
        parameters: {'keyword': keyword},
      );
    } catch (e) {
      debugPrint('Analytics logViewKeyword error: $e');
    }
  }

  static Future<void> logViewAuthor({required String authorName}) async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(
        name: 'view_author',
        parameters: {'author_name': authorName},
      );
    } catch (e) {
      debugPrint('Analytics logViewAuthor error: $e');
    }
  }

  static Future<void> logExportPdf(String topic) async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(
        name: 'export_pdf',
        parameters: {'topic': topic},
      );
    } catch (e) {
      debugPrint('Analytics logExportPdf error: $e');
    }
  }

  static Future<void> logOpenPaper({required String title}) async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(
        name: 'open_paper',
        parameters: {
          'title': title.length > 100 ? title.substring(0, 100) : title,
        },
      );
    } catch (e) {
      debugPrint('Analytics logOpenPaper error: $e');
    }
  }

  static Future<void> logOpenDoi({required String doi}) async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(
        name: 'open_doi',
        parameters: {'doi': doi},
      );
    } catch (e) {
      debugPrint('Analytics logOpenDoi error: $e');
    }
  }

  static Future<void> logLoadMorePapers({
    required String source,
    required int currentCount,
  }) async {
    final a = _instance;
    if (a == null) return;
    try {
      await a.logEvent(
        name: 'load_more_papers',
        parameters: {
          'source': source,
          'current_count': currentCount,
        },
      );
    } catch (e) {
      debugPrint('Analytics logLoadMorePapers error: $e');
    }
  }
}
