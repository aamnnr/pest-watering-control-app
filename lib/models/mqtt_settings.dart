import '../core/protocol/firmware_protocol.dart';

class MqttSettings {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool useTls;
  final String telemetryTopicTemplate;
  final String commandTopicTemplate;
  final String clientIdPrefix;
  final int batteryAlertThreshold;
  final int offlineThresholdMinutes;

  const MqttSettings({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.useTls,
    required this.telemetryTopicTemplate,
    required this.commandTopicTemplate,
    required this.clientIdPrefix,
    required this.batteryAlertThreshold,
    required this.offlineThresholdMinutes,
  });

  factory MqttSettings.defaults() {
    return const MqttSettings(
      host: FirmwareProtocol.defaultBrokerHost,
      port: FirmwareProtocol.defaultBrokerPort,
      username: '',
      password: '',
      useTls: false,
      telemetryTopicTemplate: FirmwareProtocol.telemetryTopicTemplate,
      commandTopicTemplate: FirmwareProtocol.commandTopicTemplate,
      clientIdPrefix: FirmwareProtocol.clientIdPrefix,
      batteryAlertThreshold: 20,
      offlineThresholdMinutes: 15,
    );
  }

  factory MqttSettings.fromJson(Map<String, dynamic> json) {
    final defaults = MqttSettings.defaults();
    return MqttSettings(
      host: (json['host'] as String?)?.trim().isNotEmpty == true
          ? (json['host'] as String).trim()
          : defaults.host,
      port: _parseInt(json['port']) ?? defaults.port,
      username: (json['username'] as String?)?.trim() ?? defaults.username,
      password: (json['password'] as String?) ?? defaults.password,
      useTls: json['useTls'] == true,
      telemetryTopicTemplate:
          (json['telemetryTopicTemplate'] as String?)?.trim().isNotEmpty == true
              ? (json['telemetryTopicTemplate'] as String).trim()
              : defaults.telemetryTopicTemplate,
      commandTopicTemplate:
          (json['commandTopicTemplate'] as String?)?.trim().isNotEmpty == true
              ? (json['commandTopicTemplate'] as String).trim()
              : defaults.commandTopicTemplate,
      clientIdPrefix:
          (json['clientIdPrefix'] as String?)?.trim().isNotEmpty == true
              ? (json['clientIdPrefix'] as String).trim()
              : defaults.clientIdPrefix,
      batteryAlertThreshold:
          _parseInt(json['batteryAlertThreshold']) ??
              defaults.batteryAlertThreshold,
      offlineThresholdMinutes:
          _parseInt(json['offlineThresholdMinutes']) ??
              defaults.offlineThresholdMinutes,
    );
  }

  static int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'useTls': useTls,
      'telemetryTopicTemplate': telemetryTopicTemplate,
      'commandTopicTemplate': commandTopicTemplate,
      'clientIdPrefix': clientIdPrefix,
      'batteryAlertThreshold': batteryAlertThreshold,
      'offlineThresholdMinutes': offlineThresholdMinutes,
    };
  }

  String telemetryTopicFor(String deviceId) =>
      telemetryTopicTemplate.replaceAll('{deviceId}', deviceId);

  String commandTopicFor(String deviceId) =>
      commandTopicTemplate.replaceAll('{deviceId}', deviceId);

  MqttSettings copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    bool? useTls,
    String? telemetryTopicTemplate,
    String? commandTopicTemplate,
    String? clientIdPrefix,
    int? batteryAlertThreshold,
    int? offlineThresholdMinutes,
  }) {
    return MqttSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      useTls: useTls ?? this.useTls,
      telemetryTopicTemplate:
          telemetryTopicTemplate ?? this.telemetryTopicTemplate,
      commandTopicTemplate: commandTopicTemplate ?? this.commandTopicTemplate,
      clientIdPrefix: clientIdPrefix ?? this.clientIdPrefix,
      batteryAlertThreshold:
          batteryAlertThreshold ?? this.batteryAlertThreshold,
      offlineThresholdMinutes:
          offlineThresholdMinutes ?? this.offlineThresholdMinutes,
    );
  }
}
