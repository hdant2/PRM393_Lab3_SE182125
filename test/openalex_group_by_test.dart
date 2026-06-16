import 'package:flutter_test/flutter_test.dart';

import 'package:lab2/services/openalex_service.dart';

void main() {
  test('parseGroupByYear reads OpenAlex group_by counts', () {
    final trend = OpenAlexService.parseGroupByYear({
      'group_by': [
        {'key': '2020', 'count': 10200000},
        {'key': '2021', 'count': 9800000},
        {'key': 'null', 'count': 100},
      ],
    });

    expect(trend[2020], 10200000);
    expect(trend[2021], 9800000);
    expect(trend.length, 2);
  });

  test('parseGroupByNamedCounts sorts by count and uses display names', () {
    final ranked = OpenAlexService.parseGroupByNamedCounts({
      'group_by': [
        {
          'key': 'https://openalex.org/A1',
          'key_display_name': 'Alice',
          'count': 12,
        },
        {
          'key': 'https://openalex.org/A2',
          'key_display_name': 'Bob',
          'count': 99,
        },
        {'key': 'null', 'key_display_name': 'Unknown', 'count': 5},
      ],
    }, limit: 2);

    expect(ranked.length, 2);
    expect(ranked.first.name, 'Bob');
    expect(ranked.first.count, 99);
    expect(ranked[1].name, 'Alice');
  });
}
