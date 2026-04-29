import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/storage_service.dart';
import '../../models/telemetry_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TelemetryModel> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final storage = GetIt.instance<StorageService>();
    setState(() {
      _history = storage.getTelemetryHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat & Grafik'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory)],
      ),
      body: _history.isEmpty
          ? const Center(child: Text('Belum ada data. Tunggu perangkat mengirim telemetry.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Grafik Baterai', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: const FlTitlesData(show: true),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _getSpots(),
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Log Aktivitas', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length > 50 ? 50 : _history.length,
                          itemBuilder: (_, i) {
                            final data = _history[_history.length - 1 - i];
                            return ListTile(
                              leading: Icon(data.uv == 1 ? Icons.lightbulb : Icons.lightbulb_outline,
                                  color: data.uv == 1 ? Colors.amber : Colors.grey),
                              title: Text('Baterai: ${data.bat}% | UV: ${data.uv == 1 ? "ON" : "OFF"}'),
                              subtitle: Text(data.time ?? 'Waktu tidak tercatat'),
                              dense: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<FlSpot> _getSpots() {
    if (_history.isEmpty) return [];
    return List.generate(_history.length, (i) => FlSpot(i.toDouble(), _history[i].bat.toDouble()));
  }
}