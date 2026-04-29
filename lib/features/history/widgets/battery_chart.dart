import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/telemetry_model.dart';

class BatteryChart extends StatelessWidget {
  final List<TelemetryModel> data;
  const BatteryChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].bat.toDouble()));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grafik Baterai (7 hari)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(spots: spots, isCurved: true, color: Colors.green, barWidth: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}