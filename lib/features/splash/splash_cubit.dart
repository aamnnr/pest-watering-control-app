import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/mqtt_service.dart';
import '../../models/device_model.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final StorageService storage;
  SplashCubit(this.storage) : super(const SplashInitial());

  void checkDevice() async {
    await Future.delayed(const Duration(seconds: 2));
    final device = storage.getActiveDevice();
    if (device == null) {
      emit(const SplashNoDevice());
    } else {
      final mqttService = MqttService(
        deviceId: device.deviceId,
        onTelemetryReceived: (_) {},
      );
      emit(SplashHasDevice(device, mqttService));
    }
  }
}