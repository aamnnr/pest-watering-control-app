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
      pump: fields[4] as int? ?? 0,
      deviceId: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, TelemetryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.bat)
      ..writeByte(1)
      ..write(obj.isNight)
      ..writeByte(2)
      ..write(obj.uv)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.pump)
      ..writeByte(5)
      ..write(obj.deviceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TelemetryModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
