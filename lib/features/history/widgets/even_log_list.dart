// lib/features/history/widgets/event_log_list.dart
import 'package:flutter/material.dart';
import '../../../models/telemetry_model.dart';

class EventLogList extends StatelessWidget {
  final List<TelemetryModel> data;
  const EventLogList({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Log Aktivitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length > 20 ? 20 : data.length,
              itemBuilder: (_, i) {
                final item = data[data.length - 1 - i];
                return ListTile(
                  leading: Icon(item.uv == 1 ? Icons.lightbulb : Icons.lightbulb_outline),
                  title: Text('Baterai: ${item.bat}% | UV: ${item.uv == 1 ? "ON" : "OFF"}'),
                  subtitle: Text(item.time ?? 'Waktu tidak tersedia'),
                  dense: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}