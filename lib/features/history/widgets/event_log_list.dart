import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/activity_log_entry.dart';

class EventLogList extends StatelessWidget {
  final List<ActivityLogEntry> logs;

  const EventLogList({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Log Aktivitas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              const Text('Belum ada log aktivitas.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (_, i) {
                  final item = logs[i];
                  return ListTile(
                    leading: Icon(
                      switch (item.type) {
                        ActivityLogType.alert => Icons.warning_amber_rounded,
                        ActivityLogType.command => Icons.settings_remote,
                        ActivityLogType.telemetry => Icons.monitor_heart,
                        ActivityLogType.system => Icons.info_outline,
                      },
                    ),
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.detail}\n${DateFormat('dd MMM yyyy, HH:mm').format(item.timestamp)}',
                    ),
                    dense: true,
                    isThreeLine: true,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
