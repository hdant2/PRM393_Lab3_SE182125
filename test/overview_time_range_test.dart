import 'package:flutter_test/flutter_test.dart';
import 'package:lab2/utils/overview_time_range.dart';

void main() {
  test('filterYearlyDataByRange keeps only selected years', () {
    final currentYear = DateTime.now().year;
    final source = {
      currentYear - 4: 10,
      currentYear - 3: 20,
      currentYear - 2: 30,
      currentYear - 1: 40,
      currentYear: 50,
    };

    final thisYear = filterYearlyDataByRange(
      source,
      OverviewTimeRange.thisYear,
    );
    expect(thisYear.containsKey(currentYear), isTrue);
    expect(thisYear.length, 1);

    final fiveYears = filterYearlyDataByRange(
      source,
      OverviewTimeRange.fiveYears,
    );
    expect(fiveYears.keys.length, 5);
    expect(fiveYears.keys.every((y) => y >= currentYear - 4), isTrue);
  });
}
