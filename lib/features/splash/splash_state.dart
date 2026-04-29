part of 'splash_cubit.dart';

abstract class SplashState extends Equatable {
  const SplashState();
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashNoDevice extends SplashState {
  const SplashNoDevice();
}

class SplashHasDevice extends SplashState {
  final DeviceModel device;
  final MqttService mqttService;
  const SplashHasDevice(this.device, this.mqttService);
  @override
  List<Object?> get props => [device, mqttService];
}