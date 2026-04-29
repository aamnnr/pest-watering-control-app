// lib/models/device_model.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceModelAdapter extends TypeAdapter<DeviceModel> {
  @override
  final int typeId = 1;

  @override
  DeviceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceModel(
      deviceId: fields[0] as String,
      name: fields[1] as String,
      lastSeen: fields[2] as DateTime,
      lastBattery: fields[3] as int,
      uvStartHour: fields[4] as int,
      uvEndHour: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.lastSeen)
      ..writeByte(3)
      ..write(obj.lastBattery)
      ..writeByte(4)
      ..write(obj.uvStartHour)
      ..writeByte(5)
      ..write(obj.uvEndHour);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeviceModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}