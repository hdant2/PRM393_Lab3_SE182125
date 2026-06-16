import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// recent_searches_service.dart — LỊCH SỬ SEARCH (SharedPreferences)
// =============================================================================
// Lưu tối đa 8 topic gần nhất — hiện trên tab Home và Explore.
// =============================================================================

/// Lưu lịch sử search topic trên máy (tab Home / Explore).
class RecentSearchesService {
  static const String storageKey = 'recent_search_topics';
  static const int maxItems = 8;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(storageKey) ?? [];
  }

  /// Thêm topic lên đầu, bỏ trùng, giữ max 8
  Future<List<String>> add(String topic) async {
    final trimmed = topic.trim();
    if (trimmed.isEmpty) return load();

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(storageKey) ?? [];

    final updated = [
      trimmed,
      ...current.where((item) => item.toLowerCase() != trimmed.toLowerCase()),
    ].take(maxItems).toList();

    await prefs.setStringList(storageKey, updated);
    return updated;
  }

  Future<List<String>> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    return [];
  }
}
