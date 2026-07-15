import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static int get maxJournals =>
      FirebaseRemoteConfig.instance.getInt('max_journals_displayed');

  static int get maxKeywords =>
      FirebaseRemoteConfig.instance.getInt('max_keywords_displayed');

  static Map<String, RemoteConfigValue> getAll() {
    return FirebaseRemoteConfig.instance.getAll();
  }
}
