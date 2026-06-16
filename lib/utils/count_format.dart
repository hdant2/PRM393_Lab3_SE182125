// =============================================================================
// count_format.dart — ĐỊNH DẠNG SỐ LỚN CHO UI
// =============================================================================
// OpenAlex trả count rất lớn (201700 → "201.7K") — dùng thống nhất toàn app.
// =============================================================================

/// Rút gọn: 1500 → 1.5K, 201700 → 201.7K, 1200000 → 1.2M
String formatOpenAlexCount(int value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

/// Hiển thị đầy đủ có dấu phẩy: 201700 → 201,700
String formatOpenAlexCountFull(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
}
