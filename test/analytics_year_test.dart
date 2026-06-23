import 'package:flutter_test/flutter_test.dart';
import 'package:lab2/utils/analytics_year.dart';

void main() {
  test('filterYearlyFromAnalyticsStart drops years before 2000', () {
    final filtered = filterYearlyFromAnalyticsStart({
      1800: 10,
      1999: 5,
      2000: 20,
      2024: 30,
    });

    expect(filtered.keys, [2000, 2024]);
    expect(filtered[2000], 20);
    expect(filtered[2024], 30);
  });
}
