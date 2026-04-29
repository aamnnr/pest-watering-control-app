import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/storage_service.dart';
import '../../models/activity_log_entry.dart';
import '../../models/telemetry_model.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final StorageService storage;
  final String deviceId;

  HistoryCubit(this.storage, {required this.deviceId})
      : super(const HistoryLoading());

  void loadHistory() {
    final telemetry = storage.getTelemetryHistory(deviceId: deviceId);
    final logs = storage.getActivityLogs(limit: 50, deviceId: deviceId);
    emit(
      HistoryLoaded(
        telemetry: telemetry,
        logs: logs,
      ),
    );
  }
}
