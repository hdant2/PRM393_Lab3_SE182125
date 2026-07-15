import 'package:firebase_messaging/firebase_messaging.dart';

class MessagingService {
  static final List<RemoteMessage> _messages = [];
  static List<RemoteMessage> get messages =>
      List.unmodifiable(_messages);

  static void init() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen((msg) => _messages.insert(0, msg));
      FirebaseMessaging.onMessageOpenedApp.listen((msg) => _messages.insert(0, msg));

      final initial = await messaging.getInitialMessage();
      if (initial != null) _messages.insert(0, initial);
    } catch (_) {}
  }
}
