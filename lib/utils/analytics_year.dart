/// Năm bắt đầu tổng hợp dữ liệu bibliometric trong app.
const int kAnalyticsStartYear = 2000;

Map<int, int> filterYearlyFromAnalyticsStart(Map<int, int> source) {
  if (source.isEmpty) return source;

  return Map.fromEntries(
    source.entries.where((entry) => entry.key >= kAnalyticsStartYear),
  );
}
