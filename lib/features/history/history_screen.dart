import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/storage_service.dart';
import '../../models/device_model.dart';
import 'history_cubit.dart';
import 'widgets/battery_chart.dart';
import 'widgets/event_log_list.dart';

class HistoryScreen extends StatelessWidget {
  final DeviceModel device;

  const HistoryScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(
        GetIt.instance<StorageService>(),
        deviceId: device.deviceId,
      )..loadHistory(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat & Grafik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HistoryCubit>().loadHistory(),
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryLoaded) {
            if (state.telemetry.isEmpty && state.logs.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada data. Tunggu perangkat mengirim telemetry.',
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                BatteryChart(data: state.telemetry),
                const SizedBox(height: 16),
                EventLogList(logs: state.logs),
              ],
            );
          }

          if (state is HistoryError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
