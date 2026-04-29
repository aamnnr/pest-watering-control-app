import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/protocol/firmware_protocol.dart';
import '../../core/services/mqtt_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/activity_log_entry.dart';
import '../../models/device_model.dart';
import '../../models/mqtt_settings.dart';
import '../../models/telemetry_model.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final StorageService storage;
  DeviceModel device;
  late MqttSettings _mqttSettings;
  late MqttService mqttService;
  Timer? _offlineTimer;
  bool _offlineNotificationSent = false;
  bool _batteryWarningSent = false;

  DashboardCubit({required this.storage, required this.device})
      : super(
          DashboardState.initial(
            device: device,
            telemetry: storage.getLatestTelemetry(deviceId: device.deviceId),
            isOffline: false,
            recentLogs: storage.getActivityLogs(
              limit: AppConstants.dashboardRecentLogLimit,
              deviceId: device.deviceId,
            ),
          ),
        ) {
    _mqttSettings = storage.getMqttSettings();
    emit(
      state.copyWith(
        telemetry: storage.getLatestTelemetry(deviceId: device.deviceId),
        isOffline: _isOffline(device.lastSeen),
      ),
    );
    _createMqttService();
    _connectMqtt();
    _startOfflineChecker();
  }

  void _createMqttService() {
    mqttService = MqttService(
      deviceId: device.deviceId,
      settings: _mqttSettings,
      onTelemetryReceived: _onTelemetryReceived,
      onConnectionChanged: _onConnectionChanged,
    );
  }

  Future<void> _connectMqtt() async {
    emit(
      state.copyWith(
        connectionStatus: DashboardConnectionStatus.connecting,
        clearError: true,
      ),
    );

    final connected = await mqttService.connect();
    if (!connected) {
      await _appendLog(
        ActivityLogEntry(
          type: ActivityLogType.alert,
          timestamp: DateTime.now(),
          title: 'Koneksi MQTT gagal',
          detail:
              'Periksa host, port, kredensial, dan topic untuk perangkat ${device.deviceId}.',
          deviceId: device.deviceId,
        ),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            connectionStatus: DashboardConnectionStatus.error,
            errorMessage: 'Gagal terhubung ke MQTT.',
          ),
        );
      }
    }
  }

  Future<void> _onTelemetryReceived(TelemetryModel telemetry) async {
    final telemetryWithTimestamp = telemetry.time == null
        ? telemetry.copyWith(time: DateTime.now().toIso8601String())
        : telemetry;

    await storage.saveTelemetry(telemetryWithTimestamp);
    device = device.copyWith(
      lastSeen: telemetryWithTimestamp.timestamp,
      lastBattery: telemetryWithTimestamp.bat,
    );
    await storage.saveDevice(device);

    if (_offlineNotificationSent) {
      _offlineNotificationSent = false;
      await NotificationService.showDeviceBackOnline(device.deviceId);
      await _appendLog(
        ActivityLogEntry(
          type: ActivityLogType.system,
          timestamp: DateTime.now(),
          title: 'Sinkronisasi kembali normal',
          detail: 'Perangkat kembali mengirim telemetry.',
          deviceId: device.deviceId,
        ),
      );
    }

    if (telemetryWithTimestamp.bat <= _mqttSettings.batteryAlertThreshold &&
        !_batteryWarningSent) {
      _batteryWarningSent = true;
      await NotificationService.showBatteryWarning(telemetryWithTimestamp.bat);
      await _appendLog(
        ActivityLogEntry(
          type: ActivityLogType.alert,
          timestamp: DateTime.now(),
          title: 'Baterai rendah',
          detail:
              'Kapasitas baterai turun ke ${telemetryWithTimestamp.bat}% pada perangkat ${device.name}.',
          deviceId: device.deviceId,
        ),
      );
    } else if (telemetryWithTimestamp.bat >
        _mqttSettings.batteryAlertThreshold) {
      _batteryWarningSent = false;
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          device: device,
          telemetry: telemetryWithTimestamp,
          connectionStatus: DashboardConnectionStatus.connected,
          isOffline: false,
          recentLogs: storage.getActivityLogs(
            limit: AppConstants.dashboardRecentLogLimit,
            deviceId: device.deviceId,
          ),
          clearError: true,
        ),
      );
    }
  }

  void _startOfflineChecker() {
    _offlineTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkOfflineStatus(),
    );
  }

  void _onConnectionChanged(bool isConnected) {
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        connectionStatus: isConnected
            ? DashboardConnectionStatus.connected
            : DashboardConnectionStatus.disconnected,
      ),
    );
  }

  Future<void> _checkOfflineStatus() async {
    final offline = _isOffline(device.lastSeen);
    if (!isClosed && offline != state.isOffline) {
      emit(state.copyWith(isOffline: offline));
    }

    if (offline && !_offlineNotificationSent) {
      _offlineNotificationSent = true;
      await NotificationService.showDeviceOffline(
        device.deviceId,
        thresholdMinutes: _mqttSettings.offlineThresholdMinutes,
      );
      await _appendLog(
        ActivityLogEntry(
          type: ActivityLogType.alert,
          timestamp: DateTime.now(),
          title: 'Perangkat offline',
          detail:
              'Tidak ada telemetry selama lebih dari ${_mqttSettings.offlineThresholdMinutes} menit.',
          deviceId: device.deviceId,
        ),
      );
    }
  }

  bool _isOffline(DateTime lastSeen) {
    return DateTime.now().difference(lastSeen).inMinutes >=
        _mqttSettings.offlineThresholdMinutes;
  }

  Future<void> _appendLog(ActivityLogEntry entry) async {
    await storage.saveActivityLog(entry);
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        recentLogs: storage.getActivityLogs(
          limit: AppConstants.dashboardRecentLogLimit,
          deviceId: device.deviceId,
        ),
      ),
    );
  }

  Future<CommandDispatchResult> runPumpFor(int durationSec) async {
    final result = mqttService.sendPumpSpray(durationSec);
    if (result.isSuccess) {
      await _appendLog(
        ActivityLogEntry(
          type: ActivityLogType.command,
          timestamp: DateTime.now(),
          title: 'Semprot manual',
          detail: 'Perintah semprot $durationSec detik dikirim ke broker.',
          deviceId: device.deviceId,
        ),
      );
    }
    return result;
  }

  Future<CommandDispatchResult> updateSchedule(int start, int end) async {
    if (!FirmwareProtocol.isValidSchedule(start, end)) {
      return const CommandDispatchResult.invalid(
        'Jadwal harus berada dalam hari yang sama dan jam selesai harus lebih besar dari jam mulai.',
      );
    }

    final result = mqttService.updateSchedule(start, end);
    if (!result.isSuccess) {
      return result;
    }

    device = device.copyWith(
      uvStartHour: start,
      uvEndHour: end,
    );
    await storage.saveDevice(device);
    emit(state.copyWith(device: device));
    await _appendLog(
      ActivityLogEntry(
        type: ActivityLogType.command,
        timestamp: DateTime.now(),
        title: 'Jadwal diperbarui',
        detail:
            'Perintah jadwal UV ${start.toString().padLeft(2, '0')}:00 - ${end.toString().padLeft(2, '0')}:00 dikirim ke broker.',
        deviceId: device.deviceId,
      ),
    );
    return result;
  }

  Future<void> refreshTelemetry() async {
    await _connectMqtt();
  }

  Future<void> reloadConfiguration() async {
    mqttService.disconnect();
    final activeDevice = storage.getActiveDevice();
    if (activeDevice != null) {
      device = activeDevice;
    }
    _mqttSettings = storage.getMqttSettings();
    _createMqttService();
    emit(
      state.copyWith(
        device: device,
        telemetry: storage.getLatestTelemetry(deviceId: device.deviceId),
        recentLogs: storage.getActivityLogs(
          limit: AppConstants.dashboardRecentLogLimit,
          deviceId: device.deviceId,
        ),
        isOffline: _isOffline(device.lastSeen),
        connectionStatus: DashboardConnectionStatus.initial,
        clearError: true,
      ),
    );
    await _connectMqtt();
  }

  @override
  Future<void> close() {
    _offlineTimer?.cancel();
    mqttService.disconnect();
    return super.close();
  }
}
