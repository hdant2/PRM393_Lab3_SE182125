import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static bool _initialized = false;

  /// Fetch + activate Remote Config; set defaults so UI không hiện 0 khi offline.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval: const Duration(minutes: 1),
        ),
      );
      await remoteConfig.setDefaults(const {
        'max_journals_displayed': 10,
        'max_keywords_displayed': 10,
      });
      await remoteConfig.fetchAndActivate();
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  /// Tải lại từ Firebase Console (demo Remote Config live).
  static Future<bool> refresh() async {
    _initialized = false;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await remoteConfig.fetchAndActivate();
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = true;
      return false;
    }
  }

  static int get maxJournals {
    try {
      final value =
          FirebaseRemoteConfig.instance.getInt('max_journals_displayed');
      return value > 0 ? value : 10;
    } catch (_) {
      return 10;
    }
  }

  static int get maxKeywords {
    try {
      final value =
          FirebaseRemoteConfig.instance.getInt('max_keywords_displayed');
      return value > 0 ? value : 10;
    } catch (_) {
      return 10;
    }
  }

  static Map<String, RemoteConfigValue> getAll() {
    return FirebaseRemoteConfig.instance.getAll();
  }
}
