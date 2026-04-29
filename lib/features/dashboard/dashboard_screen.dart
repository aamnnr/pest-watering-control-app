import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'dashboard_cubit.dart';
import '../../models/device_model.dart';
import '../../core/services/storage_service.dart';
import 'widgets/battery_card.dart';
import 'widgets/uv_control_card.dart';
import 'widgets/pump_control_card.dart';
import 'widgets/last_seen_card.dart';

class DashboardScreen extends StatelessWidget {
  final DeviceModel device;
  const DashboardScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(
        storage: GetIt.instance<StorageService>(),
        device: device,
      ),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.schedule), onPressed: () => Navigator.pushNamed(context, '/schedule')),
          IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.pushNamed(context, '/history')),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings')),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardDataUpdated) {
            return RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  BatteryCard(batteryPercent: state.telemetry.bat),
                  const SizedBox(height: 16),
                  UvControlCard(
                    isUvOn: state.telemetry.uv == 1,
                    onToggle: (val) => context.read<DashboardCubit>().toggleUv(val),
                  ),
                  const SizedBox(height: 16),
                  PumpControlCard(
                    onPump: (dur) => context.read<DashboardCubit>().triggerPump(dur),
                  ),
                  const SizedBox(height: 16),
                  LastSeenCard(lastSeen: state.lastSeen),
                ],
              ),
            );
          } else if (state is DashboardConnected) {
            return const Center(child: Text('Menunggu data dari perangkat...'));
          } else if (state is DashboardError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}