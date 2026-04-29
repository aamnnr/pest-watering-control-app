import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/telemetry_model.dart';
import '../../models/device_model.dart';
import '../../core/services/mqtt_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/notification_service.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  late MqttService mqttService;
  final StorageService storage;
  final DeviceModel device;
  Timer? _offlineTimer;

  DashboardCubit({required this.storage, required this.device}) : super(DashboardInitial()) {
    mqttService = MqttService(
      deviceId: device.deviceId,
      onTelemetryReceived: _onTelemetryReceived,
    );
    _connectMqtt();
    _startOfflineChecker();
  }

  void _connectMqtt() async {
    emit(DashboardLoading());
    final connected = await mqttService.connect();
    if (connected) {
      emit(DashboardConnected());
    } else {
      emit(DashboardError('Gagal terhubung ke MQTT'));
    }
  }

  void _onTelemetryReceived(TelemetryModel telemetry) {
    storage.saveTelemetry(telemetry);
    device.lastSeen = DateTime.now();
    device.lastBattery = telemetry.bat;
    storage.saveDevice(device);
    emit(DashboardDataUpdated(telemetry: telemetry, lastSeen: device.lastSeen));
    if (telemetry.bat <= 20) {
      NotificationService.showBatteryWarning(telemetry.bat);
    }
  }

  void _startOfflineChecker() {
    _offlineTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (DateTime.now().difference(device.lastSeen).inMinutes > 15) {
        NotificationService.showDeviceOffline(device.deviceId);
      }
    });
  }

  void toggleUv(bool isOn) {
    if (isOn) {
      mqttService.sendUvSchedule(0, 24);
      device.uvStartHour = 0;
      device.uvEndHour = 24;
    } else {
      mqttService.sendUvSchedule(0, 0);
      device.uvStartHour = 0;
      device.uvEndHour = 0;
    }
    storage.saveDevice(device);
  }

  void triggerPump(int durationSec) {
    mqttService.sendPump(durationSec);
  }

  void updateSchedule(int start, int end) {
    mqttService.sendUvSchedule(start, end);
    device.uvStartHour = start;
    device.uvEndHour = end;
    storage.saveDevice(device);
  }

  @override
  Future<void> close() {
    _offlineTimer?.cancel();
    mqttService.disconnect();
    return super.close();
  }
}