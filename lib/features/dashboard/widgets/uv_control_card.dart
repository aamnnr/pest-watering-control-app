import 'package:flutter/material.dart';

class UvControlCard extends StatelessWidget {
  final bool isUvOn;
  final String scheduleLabel;
  final VoidCallback onOpenSchedule;

  const UvControlCard({
    super.key,
    required this.isUvOn,
    required this.scheduleLabel,
    required this.onOpenSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lampu UV',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(
                  isUvOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: isUvOn ? Colors.amber : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isUvOn ? 'UV menyala' : 'UV mati',
              style: TextStyle(color: isUvOn ? Colors.amber : Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Firmware mengatur UV secara otomatis dari jadwal tersimpan dan kondisi malam.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Jadwal: $scheduleLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpenSchedule,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('Atur'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
