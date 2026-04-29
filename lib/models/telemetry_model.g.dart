// lib/models/telemetry_model.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TelemetryModelAdapter extends TypeAdapter<TelemetryModel> {
  @override
  final int typeId = 0;

  @override
  TelemetryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TelemetryModel(
      bat: fields[0] as int,
      isNight: fields[1] as bool,
      uv: fields[2] as int,
      time: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TelemetryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.bat)
      ..writeByte(1)
      ..write(obj.isNight)
      ..writeByte(2)
      ..write(obj.uv)
      ..writeByte(3)
      ..write(obj.time);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TelemetryModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TelemetryModel _$TelemetryModelFromJson(Map<String, dynamic> json) => TelemetryModel(
      bat: json['bat'] as int,
      isNight: json['is_night'] as bool,
      uv: json['uv'] as int,
      time: json['time'] as String?,
    );

Map<String, dynamic> _$TelemetryModelToJson(TelemetryModel instance) => <String, dynamic>{
      'bat': instance.bat,
      'is_night': instance.isNight,
      'uv': instance.uv,
      'time': instance.time,
    };