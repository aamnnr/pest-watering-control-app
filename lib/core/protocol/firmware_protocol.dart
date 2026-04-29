class FirmwareProtocol {
  static const String defaultBrokerHost = 'broker.hivemq.com';
  static const int defaultBrokerPort = 1883;
  static const String telemetryTopicTemplate =
      'tanisolution/{deviceId}/telemetry';
  static const String commandTopicTemplate =
      'tanisolution/{deviceId}/command';
  static const String clientIdPrefix = 'pestmist_app';
  static const String bleDeviceNamePrefix = 'Alburdat_Setup_';
  static const String bleProvisioningServiceUuid =
      '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String bleProvisioningCharacteristicUuid =
      'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  static String? extractDeviceIdFromBleName(String value) {
    final normalized = value.trim();
    if (!normalized.startsWith(bleDeviceNamePrefix)) {
      return null;
    }

    final suffix = normalized.substring(bleDeviceNamePrefix.length).trim();
    if (suffix.isEmpty) {
      return null;
    }

    return suffix;
  }

  static bool isValidSchedule(int startHour, int endHour) {
    return startHour >= 0 &&
        startHour <= 23 &&
        endHour >= 0 &&
        endHour <= 23 &&
        startHour < endHour;
  }

  static Map<String, dynamic> buildPumpSprayCommand(int durationSec) {
    final sanitizedDuration = durationSec.clamp(1, 120).toInt();
    return <String, dynamic>{
      'pump_action': 'ON',
      'duration_sec': sanitizedDuration,
    };
  }

  static Map<String, dynamic> buildScheduleCommand(
    int startHour,
    int endHour,
  ) {
    return <String, dynamic>{
      'uv_start': startHour,
      'uv_stop': endHour,
    };
  }
}
