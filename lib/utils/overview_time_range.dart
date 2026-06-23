import 'analytics_year.dart';

/// Khoảng thời gian lọc biểu đồ Overview (SCIENTIA-style).
enum OverviewTimeRange {
  thisYear,
  fiveYears,
  tenYears,
}

extension OverviewTimeRangeX on OverviewTimeRange {
  String get label {
    switch (this) {
      case OverviewTimeRange.thisYear:
        return 'Năm nay';
      case OverviewTimeRange.fiveYears:
        return '5 năm';
      case OverviewTimeRange.tenYears:
        return '10 năm';
    }
  }

  String coverageLabel(int currentYear) {
    switch (this) {
      case OverviewTimeRange.thisYear:
        return '$currentYear';
      case OverviewTimeRange.fiveYears:
        return '${currentYear - 4}–$currentYear';
      case OverviewTimeRange.tenYears:
        return '${currentYear - 9}–$currentYear';
    }
  }

  String coverageLabelWithMonths(int currentYear, Map<int, int> monthly) {
    if (this != OverviewTimeRange.thisYear || monthly.isEmpty) {
      return coverageLabel(currentYear);
    }
    final months = monthly.keys.toList()..sort();
    return '${monthShortLabel(months.first)}–${monthShortLabel(months.last)} $currentYear';
  }

  /// Nhãn ngắn cho Growth YoY trên card snapshot.
  String growthLabel(int currentYear) {
    switch (this) {
      case OverviewTimeRange.thisYear:
        return 'Growth (YoY month)';
      case OverviewTimeRange.fiveYears:
        return 'Growth (${currentYear - 4}→${currentYear - 1})';
      case OverviewTimeRange.tenYears:
        return 'Growth (${currentYear - 9}→${currentYear - 1})';
    }
  }
}

const _monthShortLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String monthShortLabel(int month) {
  if (month < 1 || month > 12) return '$month';
  return _monthShortLabels[month - 1];
}

Map<int, int> filterYearlyDataByRange(
  Map<int, int> source,
  OverviewTimeRange range,
) {
  if (source.isEmpty) return source;

  final currentYear = DateTime.now().year;
  final startYear = switch (range) {
    OverviewTimeRange.thisYear => currentYear,
    OverviewTimeRange.fiveYears => currentYear - 4,
    OverviewTimeRange.tenYears => currentYear - 9,
  };

  return Map.fromEntries(
    source.entries.where(
      (entry) =>
          entry.key >= kAnalyticsStartYear &&
          entry.key >= startYear &&
          entry.key <= currentYear,
    ),
  );
}

/// Volume trong khoảng đã chọn — tháng (năm nay) hoặc năm (5/10 năm).
Map<int, int> volumeInRangeFor({
  required OverviewTimeRange range,
  required Map<int, int> yearlyTrend,
  required Map<int, int> monthlyTrend,
}) {
  if (range == OverviewTimeRange.thisYear) {
    return Map<int, int>.from(monthlyTrend);
  }
  return filterYearlyFromAnalyticsStart(
    filterYearlyDataByRange(yearlyTrend, range),
  );
}
