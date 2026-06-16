import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cấu hình OpenAlex API key — dùng chung cho mọi request HTTP.
///
/// Thứ tự ưu tiên khi lấy key:
///   1. Key user nhập ở tab About → lưu SharedPreferences (`openalex_api_key`)
///   2. Key build sẵn qua `--dart-define-from-file=dart_defines.json`
///
/// [ChangeNotifier]: khi save/clear key → notifyListeners() → UI About cập nhật.
class OpenAlexConfig extends ChangeNotifier {
  static const String storageKey = 'openalex_api_key';

  /// Key nhúng lúc compile (flutter run --dart-define-from-file=...)
  static const String compileTimeKey =
      String.fromEnvironment('OPENALEX_API_KEY');

  String _savedKey = '';

  /// Key thực tế gửi lên OpenAlex (?api_key=...)
  String get apiKey {
    if (_savedKey.isNotEmpty) return _savedKey;
    return compileTimeKey;
  }

  bool get hasKey => apiKey.isNotEmpty;
  bool get hasSavedKey => _savedKey.isNotEmpty;
  bool get hasCompileTimeKey => compileTimeKey.isNotEmpty;

  /// Nhãn hiển thị trên About: key từ đâu
  String get keySourceLabel {
    if (hasSavedKey) return 'Saved in app';
    if (hasCompileTimeKey) return 'Build config';
    return 'Not configured';
  }

  /// Gọi trong main() trước runApp — đọc key đã lưu trên máy
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _savedKey = prefs.getString(storageKey)?.trim() ?? '';
    notifyListeners();
  }

  /// Lưu key mới (About screen). Chuỗi rỗng = xóa key đã lưu
  Future<void> saveKey(String key) async {
    final trimmed = key.trim();
    final prefs = await SharedPreferences.getInstance();

    if (trimmed.isEmpty) {
      await prefs.remove(storageKey);
      _savedKey = '';
    } else {
      await prefs.setString(storageKey, trimmed);
      _savedKey = trimmed;
    }

    notifyListeners();
  }

  Future<void> clearSavedKey() => saveKey('');
}
