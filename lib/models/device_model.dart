import 'package:hive/hive.dart';

part 'device_model.g.dart';

@HiveType(typeId: 1)
class DeviceModel {
  @HiveField(0)
  String deviceId;
  @HiveField(1)
  String name;
  @HiveField(2)
  DateTime lastSeen;
  @HiveField(3)
  int lastBattery;
  @HiveField(4)
  int uvStartHour;
  @HiveField(5)
  int uvEndHour;

  DeviceModel({
    required this.deviceId,
    required this.name,
    required this.lastSeen,
    required this.lastBattery,
    this.uvStartHour = 18,
    this.uvEndHour = 23,
  });
}