import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../dashboard/dashboard_cubit.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late int startHour, endHour;

  @override
  void initState() {
    super.initState();
    final device = context.read<DashboardCubit>().device;
    startHour = device.uvStartHour;
    endHour = device.uvEndHour;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal UV Otomatis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Atur jam UV menyala setiap hari'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Text('Mulai jam:')),
                    Expanded(
                      child: DropdownButton<int>(
                        value: startHour,
                        items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                        onChanged: (v) => setState(() => startHour = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Text('Selesai jam:')),
                    Expanded(
                      child: DropdownButton<int>(
                        value: endHour,
                        items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                        onChanged: (v) => setState(() => endHour = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<DashboardCubit>().updateSchedule(startHour, endHour);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal terkirim')));
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Jadwal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}