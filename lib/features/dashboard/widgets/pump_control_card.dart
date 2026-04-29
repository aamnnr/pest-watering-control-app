import 'package:flutter/material.dart';

class PumpControlCard extends StatelessWidget {
  final Function(int) onPump;
  const PumpControlCard({super.key, required this.onPump});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.water_drop),
                SizedBox(width: 8),
                Text('Pompa Misting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
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
      onPressed: () => onPump(duration),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}