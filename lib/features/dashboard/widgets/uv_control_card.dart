import 'package:flutter/material.dart';

class UvControlCard extends StatelessWidget {
  final bool isUvOn;
  final Function(bool) onToggle;
  const UvControlCard({super.key, required this.isUvOn, required this.onToggle});

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
                const Text('Lampu UV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Switch(
                  value: isUvOn,
                  onChanged: onToggle,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isUvOn ? 'UV Menyala' : 'UV Mati',
              style: TextStyle(color: isUvOn ? Colors.amber : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}