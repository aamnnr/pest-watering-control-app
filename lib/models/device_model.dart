import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'device_model.g.dart';

@HiveType(typeId: 1)
class DeviceModel extends Equatable {
  @HiveField(0)
  final String deviceId;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final DateTime lastSeen;
  @HiveField(3)
  final int lastBattery;
  @HiveField(4)
  final int uvStartHour;
  @HiveField(5)
  final int uvEndHour;

  const DeviceModel({
    required this.deviceId,
    required this.name,
    required this.lastSeen,
    required this.lastBattery,
    this.uvStartHour = 18,
    this.uvEndHour = 23,
  });

  bool get hasCustomSchedule => uvStartHour != uvEndHour;

  String get scheduleLabel {
    if (uvStartHour >= uvEndHour) {
      return 'Jadwal belum valid';
    }
    return '${uvStartHour.toString().padLeft(2, '0')}:00 - '
        '${uvEndHour.toString().padLeft(2, '0')}:00';
  }

  DeviceModel copyWith({
    String? deviceId,
    String? name,
    DateTime? lastSeen,
    int? lastBattery,
    int? uvStartHour,
    int? uvEndHour,
  }) {
    return DeviceModel(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      lastSeen: lastSeen ?? this.lastSeen,
      lastBattery: lastBattery ?? this.lastBattery,
      uvStartHour: uvStartHour ?? this.uvStartHour,
      uvEndHour: uvEndHour ?? this.uvEndHour,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        name,
        lastSeen,
        lastBattery,
        uvStartHour,
        uvEndHour,
      ];
}
