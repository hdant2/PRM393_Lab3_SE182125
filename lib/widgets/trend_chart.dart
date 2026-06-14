import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Widget vẽ biểu đồ xu hướng số lượng bài báo theo năm
class TrendChart extends StatelessWidget {
  final Map<int, int> yearlyData;

  const TrendChart({
    super.key,
    required this.yearlyData,
  });

  @override
  Widget build(BuildContext context) {
    // Sắp xếp năm tăng dần
    final years = yearlyData.keys.toList()..sort();

    if (years.isEmpty) {
      return const Center(
        child: Text('No trend data available'),
      );
    }

    final spots = years
        .map(
          (year) => FlSpot(
            year.toDouble(),
            yearlyData[year]!.toDouble(),
          ),
        )
        .toList();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minX: years.first.toDouble(),
          maxX: years.last.toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text('Year'),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              axisNameWidget: Text('Publications'),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}