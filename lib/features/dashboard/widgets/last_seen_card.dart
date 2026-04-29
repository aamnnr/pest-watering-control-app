import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LastSeenCard extends StatelessWidget {
  final DateTime lastSeen;
  final bool isOffline;

  const LastSeenCard({
    super.key,
    required this.lastSeen,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final difference = DateTime.now().difference(lastSeen);
    String statusText;
    Color statusColor;
    
    if (isOffline) {
      statusText = 'Offline - ${DateFormat('HH:mm, dd MMM').format(lastSeen)}';
      statusColor = Colors.red;
    } else if (difference.inMinutes < 5) {
      statusText = 'Online';
      statusColor = Colors.green;
    } else {
      statusText = 'Terakhir ${difference.inMinutes} menit lalu';
      statusColor = Colors.orange;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.access_time, color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last Seen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(statusText, style: TextStyle(color: statusColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
