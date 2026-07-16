import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  static final List<RemoteMessage> _messages = [];
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static String? _token;

  static List<RemoteMessage> get messages => List.unmodifiable(_messages);
  static String? get token => _token;

  static void init() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      _token = await messaging.getToken();
      messaging.onTokenRefresh.listen((value) {
        _token = value;
        revision.value++;
      });

      FirebaseMessaging.onMessage.listen(_insertMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_insertMessage);

      final initial = await messaging.getInitialMessage();
      if (initial != null) _insertMessage(initial);
    } catch (_) {}
  }

  static Future<String?> refreshToken() async {
    try {
      _token = await FirebaseMessaging.instance.getToken();
      revision.value++;
      return _token;
    } catch (_) {
      return null;
    }
  }

  static void _insertMessage(RemoteMessage msg) {
    _messages.insert(0, msg);
    revision.value++;
  }
}
