import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'telemetry_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class TelemetryModel {
  @HiveField(0)
  final int bat;
  @HiveField(1)
  final bool isNight;
  @HiveField(2)
  final int uv;
  @HiveField(3)
  final String? time;

  TelemetryModel({
    required this.bat,
    required this.isNight,
    required this.uv,
    this.time,
  });

  factory TelemetryModel.fromJson(Map<String, dynamic> json) => _$TelemetryModelFromJson(json);
  Map<String, dynamic> toJson() => _$TelemetryModelToJson(this);
}