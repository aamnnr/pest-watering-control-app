import 'package:flutter/material.dart';

class BatteryCard extends StatelessWidget {
  final int batteryPercent;
  const BatteryCard({super.key, required this.batteryPercent});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Baterai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.battery_alert, color: batteryPercent < 20 ? Colors.red : Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: batteryPercent / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      batteryPercent < 20 ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                Text('$batteryPercent%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}