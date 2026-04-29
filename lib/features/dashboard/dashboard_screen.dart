import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/storage_service.dart';
import '../../models/activity_log_entry.dart';
import '../../models/device_model.dart';
import '../history/history_screen.dart';
import '../schedule/schedule_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_cubit.dart';
import 'widgets/battery_card.dart';
import 'widgets/last_seen_card.dart';
import 'widgets/pump_control_card.dart';
import 'widgets/uv_control_card.dart';

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
        title: Text(
          context.select((DashboardCubit cubit) => cubit.state.device.name),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(device: context.read<DashboardCubit>().state.device),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push<SettingsScreenResult>(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (!context.mounted || result == null) {
                return;
              }
              if (result.nextDevice != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(device: result.nextDevice!),
                  ),
                );
                return;
              }
              if (result.reloadConfiguration) {
                context.read<DashboardCubit>().reloadConfiguration();
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.connectionStatus == DashboardConnectionStatus.connecting &&
              state.telemetry == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => context.read<DashboardCubit>().refreshTelemetry(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ConnectionSummary(state: state),
                const SizedBox(height: 16),
                BatteryCard(batteryPercent: state.batteryPercent),
                const SizedBox(height: 16),
                UvControlCard(
                  isUvOn: state.isUvOn,
                  scheduleLabel: state.scheduleSummary,
                  onOpenSchedule: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<DashboardCubit>(),
                          child: const ScheduleScreen(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                PumpControlCard(
                  isPumpOn: state.isPumpOn,
                  onTimedPump: (duration) async {
                    final result =
                        await context.read<DashboardCubit>().runPumpFor(duration);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.message)),
                    );
                  },
                ),
                const SizedBox(height: 16),
                LastSeenCard(
                  lastSeen: state.device.lastSeen,
                  isOffline: state.isOffline,
                ),
                const SizedBox(height: 16),
                _RecentActivity(logs: state.recentLogs),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConnectionSummary extends StatelessWidget {
  final DashboardState state;

  const _ConnectionSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = switch (state.connectionStatus) {
      DashboardConnectionStatus.connected => Colors.green,
      DashboardConnectionStatus.connecting => Colors.orange,
      DashboardConnectionStatus.error => Colors.red,
      DashboardConnectionStatus.disconnected => Colors.red,
      DashboardConnectionStatus.initial => Colors.grey,
    };

    final statusText = switch (state.connectionStatus) {
      DashboardConnectionStatus.connected => state.isOffline
          ? 'Broker tersambung, tetapi perangkat belum sinkron.'
          : 'Perangkat aktif dan menerima telemetry.',
      DashboardConnectionStatus.connecting => 'Menghubungkan ke broker MQTT...',
      DashboardConnectionStatus.error =>
        state.errorMessage ?? 'Gagal terhubung ke broker MQTT.',
      DashboardConnectionStatus.disconnected =>
        'Koneksi broker terputus. Menunggu reconnect.',
      DashboardConnectionStatus.initial => 'Menyiapkan sesi MQTT...',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.router, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Device ID: ${state.device.deviceId}'),
            Text('Jadwal UV: ${state.scheduleSummary}'),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final List<ActivityLogEntry> logs;

  const _RecentActivity({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              const Text('Belum ada aktivitas tercatat.')
            else
              ...logs.map(
                (log) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    switch (log.type) {
                      ActivityLogType.alert => Icons.warning_amber_rounded,
                      ActivityLogType.command => Icons.settings_remote,
                      ActivityLogType.telemetry => Icons.monitor_heart,
                      ActivityLogType.system => Icons.info_outline,
                    },
                  ),
                  title: Text(log.title),
                  subtitle: Text(log.detail),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
