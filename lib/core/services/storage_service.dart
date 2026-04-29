import 'package:hive_flutter/hive_flutter.dart';
import '../../models/telemetry_model.dart';
import '../../models/device_model.dart';
 

class StorageService {
  static const String telemetryBoxName = 'telemetry';
  static const String deviceBoxName = 'device';

  late Box<TelemetryModel> _telemetryBox;
  late Box<DeviceModel> _deviceBox;

  Future<void> init() async {
    await Hive.initFlutter();
    // Register adapters secara manual
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TelemetryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DeviceModelAdapter());
    }
    _telemetryBox = await Hive.openBox<TelemetryModel>(telemetryBoxName);
    _deviceBox = await Hive.openBox<DeviceModel>(deviceBoxName);
  }

  Box<TelemetryModel> get telemetryBox => _telemetryBox;
  Box<DeviceModel> get deviceBox => _deviceBox;

  Future<void> saveTelemetry(TelemetryModel data) async {
    await _telemetryBox.add(data);
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final keysToRemove = _telemetryBox.keys.where((key) {
      final item = _telemetryBox.get(key);
      return item?.time != null && DateTime.parse(item!.time!).isBefore(cutoff);
    }).toList();
    for (var key in keysToRemove) {
      await _telemetryBox.delete(key);
    }
  }

  List<TelemetryModel> getTelemetryHistory() {
    return _telemetryBox.values.toList();
  }

  void saveDevice(DeviceModel device) {
    _deviceBox.put('active', device);
  }

  DeviceModel? getActiveDevice() {
    return _deviceBox.get('active');
  }
}