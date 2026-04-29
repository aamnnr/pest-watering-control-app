import 'package:flutter/material.dart';

class PumpControlCard extends StatelessWidget {
  final bool isPumpOn;
  final ValueChanged<int> onTimedPump;

  const PumpControlCard({
    super.key,
    required this.isPumpOn,
    required this.onTimedPump,
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
                const Row(
                  children: [
                    Icon(Icons.water_drop),
                    SizedBox(width: 8),
                    Text(
                      'Waterpump',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Icon(
                  isPumpOn ? Icons.play_circle_fill : Icons.pause_circle_filled,
                  color: isPumpOn ? Colors.blue : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isPumpOn ? 'Waterpump aktif' : 'Waterpump mati',
              style: TextStyle(color: isPumpOn ? Colors.blue : Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Firmware menerima perintah semprot berdurasi, bukan mode ON/OFF kontinu.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPumpButton(context, 'Semprot 5s', 5),
                _buildPumpButton(context, 'Semprot 10s', 10),
                _buildPumpButton(context, 'Semprot 15s', 15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpButton(BuildContext context, String label, int duration) {
    return ElevatedButton(
      onPressed: () => onTimedPump(duration),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
