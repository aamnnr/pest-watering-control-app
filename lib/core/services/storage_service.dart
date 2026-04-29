import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import '../../models/activity_log_entry.dart';
import '../../models/telemetry_model.dart';
import '../../models/device_model.dart';
import '../../models/mqtt_settings.dart';
import '../constants/app_constants.dart';

class StorageService {
  static const String telemetryBoxName = 'telemetry';
  static const String deviceBoxName = 'device';
  static const String appBoxName = 'app_state';
  static const String mqttSettingsKey = 'mqtt_settings';
  static const String activityLogsKey = 'activity_logs';
  static const String activeDeviceIdKey = 'active_device_id';

  late Box<TelemetryModel> _telemetryBox;
  late Box<DeviceModel> _deviceBox;
  late Box<dynamic> _appBox;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TelemetryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DeviceModelAdapter());
    }
    _telemetryBox = await Hive.openBox<TelemetryModel>(telemetryBoxName);
    _deviceBox = await Hive.openBox<DeviceModel>(deviceBoxName);
    _appBox = await Hive.openBox<dynamic>(appBoxName);
    await _migrateLegacyStorage();
  }

  Box<TelemetryModel> get telemetryBox => _telemetryBox;
  Box<DeviceModel> get deviceBox => _deviceBox;

  Future<void> saveTelemetry(TelemetryModel data) async {
    await _telemetryBox.add(data);
    final cutoff = DateTime.now().subtract(
      const Duration(days: AppConstants.telemetryRetentionDays),
    );
    final keysToRemove = _telemetryBox.keys.where((key) {
      final item = _telemetryBox.get(key);
      return item != null && item.timestamp.isBefore(cutoff);
    }).toList();
    for (var key in keysToRemove) {
      await _telemetryBox.delete(key);
    }
  }

  Future<void> _migrateLegacyStorage() async {
    final legacyActive = _deviceBox.get('active');
    if (legacyActive != null) {
      await _deviceBox.put(legacyActive.deviceId, legacyActive);
      await _appBox.put(activeDeviceIdKey, legacyActive.deviceId);
      await _deviceBox.delete('active');
    }
  }

  bool _matchesDevice(String itemDeviceId, String? requestedDeviceId) {
    if (requestedDeviceId == null) {
      return true;
    }
    if (itemDeviceId == requestedDeviceId) {
      return true;
    }
    return itemDeviceId.isEmpty && requestedDeviceId == getActiveDeviceId();
  }

  List<TelemetryModel> getTelemetryHistory({String? deviceId}) {
    final items = _telemetryBox.values
        .where((item) => _matchesDevice(item.deviceId, deviceId))
        .toList();
    items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return items;
  }

  TelemetryModel? getLatestTelemetry({String? deviceId}) {
    if (_telemetryBox.isEmpty) {
      return null;
    }
    final items = getTelemetryHistory(deviceId: deviceId);
    return items.isEmpty ? null : items.last;
  }

  Future<void> saveDevice(DeviceModel device, {bool setAsActive = true}) async {
    await _deviceBox.put(device.deviceId, device);
    if (setAsActive) {
      await setActiveDevice(device.deviceId);
    }
  }

  List<DeviceModel> getDevices() {
    final devices = _deviceBox.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return devices;
  }

  DeviceModel? getDevice(String deviceId) => _deviceBox.get(deviceId);

  String? getActiveDeviceId() {
    final activeId = _appBox.get(activeDeviceIdKey);
    if (activeId is String && activeId.trim().isNotEmpty) {
      return activeId;
    }
    final devices = getDevices();
    return devices.isEmpty ? null : devices.first.deviceId;
  }

  DeviceModel? getActiveDevice() {
    final activeId = getActiveDeviceId();
    if (activeId == null) {
      return null;
    }
    return _deviceBox.get(activeId);
  }

  Future<void> setActiveDevice(String deviceId) async {
    await _appBox.put(activeDeviceIdKey, deviceId);
  }

  Future<void> clearActiveDevice() async {
    await _appBox.delete(activeDeviceIdKey);
  }

  Future<void> clearTelemetryHistory({String? deviceId}) async {
    if (deviceId == null) {
      await _telemetryBox.clear();
      return;
    }
    final keysToRemove = _telemetryBox.keys.where((key) {
      final item = _telemetryBox.get(key);
      return item != null && _matchesDevice(item.deviceId, deviceId);
    }).toList();
    for (final key in keysToRemove) {
      await _telemetryBox.delete(key);
    }
  }

  MqttSettings getMqttSettings() {
    final raw = _appBox.get(mqttSettingsKey);
    if (raw is String && raw.isNotEmpty) {
      return MqttSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    }
    if (raw is Map) {
      return MqttSettings.fromJson(Map<String, dynamic>.from(raw));
    }
    return MqttSettings.defaults();
  }

  Future<void> saveMqttSettings(MqttSettings settings) async {
    await _appBox.put(mqttSettingsKey, jsonEncode(settings.toJson()));
  }

  List<ActivityLogEntry> getActivityLogs({int? limit, String? deviceId}) {
    final rawLogs = _appBox.get(activityLogsKey, defaultValue: <dynamic>[]);
    final iterable = rawLogs is List ? rawLogs : const <dynamic>[];
    final logs = iterable
        .map((item) {
          if (item is String && item.isNotEmpty) {
            return ActivityLogEntry.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          }
          if (item is Map) {
            return ActivityLogEntry.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        })
        .whereType<ActivityLogEntry>()
        .where(
          (log) => deviceId == null || _matchesDevice(log.deviceId ?? '', deviceId),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit == null || logs.length <= limit) {
      return logs;
    }
    return logs.take(limit).toList();
  }

  Future<void> saveActivityLog(ActivityLogEntry entry) async {
    final logs = getActivityLogs();
    logs.insert(0, entry);
    final trimmedLogs = logs.take(AppConstants.maxActivityLogEntries).toList();
    await _appBox.put(
      activityLogsKey,
      trimmedLogs.map((log) => jsonEncode(log.toJson())).toList(),
    );
  }

  Future<void> clearActivityLogs({String? deviceId}) async {
    if (deviceId == null) {
      await _appBox.delete(activityLogsKey);
      return;
    }
    final remainingLogs = getActivityLogs().where((log) {
      return !_matchesDevice(log.deviceId ?? '', deviceId);
    }).toList();
    await _appBox.put(
      activityLogsKey,
      remainingLogs.map((log) => jsonEncode(log.toJson())).toList(),
    );
  }

  Future<void> deleteDevice(String deviceId) async {
    await _deviceBox.delete(deviceId);
    await clearTelemetryHistory(deviceId: deviceId);
    await clearActivityLogs(deviceId: deviceId);

    if (getActiveDeviceId() == deviceId) {
      final fallbackDevice = getDevices().isEmpty ? null : getDevices().first;
      if (fallbackDevice == null) {
        await clearActiveDevice();
      } else {
        await setActiveDevice(fallbackDevice.deviceId);
      }
    }
  }

  Future<void> resetDeviceWorkspace() async {
    final activeId = getActiveDeviceId();
    if (activeId == null) {
      await clearTelemetryHistory();
      await clearActivityLogs();
      await clearActiveDevice();
      return;
    }
    await deleteDevice(activeId);
  }
}
