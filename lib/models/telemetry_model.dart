import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'telemetry_model.g.dart';

@HiveType(typeId: 0)
class TelemetryModel extends Equatable {
  @HiveField(0)
  final int bat;
  @HiveField(1)
  final bool isNight;
  @HiveField(2)
  final int uv;
  @HiveField(3)
  final String? time;
  @HiveField(4)
  final int pump;
  @HiveField(5)
  final String deviceId;

  const TelemetryModel({
    required this.bat,
    required this.isNight,
    required this.uv,
    required this.deviceId,
    this.time,
    this.pump = 0,
  });

  factory TelemetryModel.fromJson(
    Map<String, dynamic> json, {
    required String deviceId,
  }) {
    return TelemetryModel(
      bat: _readInt(json, const ['bat', 'battery', 'battery_percent']),
      isNight: _readBool(json, const ['is_night', 'isNight', 'night']),
      uv: _readInt(json, const ['uv', 'uv_state', 'uv_on']),
      pump: _readInt(json, const ['pump', 'pump_state', 'waterpump']),
      deviceId: deviceId,
      time: _readString(json, const ['time', 'timestamp', 'ts']) ??
          DateTime.now().toIso8601String(),
    );
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is bool) {
        return value ? 1 : 0;
      }
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized == 'on' || normalized == 'true') {
          return 1;
        }
        if (normalized == 'off' || normalized == 'false') {
          return 0;
        }
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized == 'true' || normalized == '1' || normalized == 'on') {
          return true;
        }
        if (normalized == 'false' ||
            normalized == '0' ||
            normalized == 'off') {
          return false;
        }
      }
    }
    return false;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  DateTime get timestamp => DateTime.tryParse(time ?? '') ?? DateTime.now();

  bool get isUvOn => uv == 1;

  bool get isPumpOn => pump == 1;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bat': bat,
      'is_night': isNight,
      'uv': uv,
      'pump': pump,
      'deviceId': deviceId,
      'time': time,
    };
  }

  TelemetryModel copyWith({
    int? bat,
    bool? isNight,
    int? uv,
    String? time,
    int? pump,
    String? deviceId,
  }) {
    return TelemetryModel(
      bat: bat ?? this.bat,
      isNight: isNight ?? this.isNight,
      uv: uv ?? this.uv,
      time: time ?? this.time,
      pump: pump ?? this.pump,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  List<Object?> get props => [bat, isNight, uv, time, pump, deviceId];
}
