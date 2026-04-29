import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../models/mqtt_settings.dart';
import '../../models/telemetry_model.dart';
import '../protocol/firmware_protocol.dart';
import '../utils/logger.dart';

enum CommandDispatchStatus {
  sent,
  unavailable,
  invalid,
}

class CommandDispatchResult {
  final CommandDispatchStatus status;
  final String message;

  const CommandDispatchResult._(this.status, this.message);

  const CommandDispatchResult.sent(String message)
      : this._(CommandDispatchStatus.sent, message);

  const CommandDispatchResult.unavailable(String message)
      : this._(CommandDispatchStatus.unavailable, message);

  const CommandDispatchResult.invalid(String message)
      : this._(CommandDispatchStatus.invalid, message);

  bool get isSuccess => status == CommandDispatchStatus.sent;
}

class MqttService {
  final String deviceId;
  final MqttSettings settings;
  final void Function(TelemetryModel) onTelemetryReceived;
  final void Function(bool isConnected)? onConnectionChanged;

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
      _updatesSubscription;
  bool _connected = false;
  String? _subscribedTopic;

  MqttService({
    required this.deviceId,
    required this.settings,
    required this.onTelemetryReceived,
    this.onConnectionChanged,
  });

  Future<bool> connect() async {
    disconnect();

    final clientId =
        '${settings.clientIdPrefix}_${deviceId}_${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(
      settings.host,
      clientId,
      settings.port,
    );

    _client = client;
    client.secure = settings.useTls;
    client.autoReconnect = true;
    client.keepAlivePeriod = 30;
    client.logging(on: false);
    client.onConnected = _handleConnected;
    client.onDisconnected = _handleDisconnected;
    client.onAutoReconnect = () => AppLogger.warning('MQTT reconnecting...');
    client.onAutoReconnected = _handleConnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillQos(MqttQos.atLeastOnce)
        .startClean();

    if (settings.username.isNotEmpty) {
      connMessage.authenticateAs(settings.username, settings.password);
    }

    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e, stackTrace) {
      AppLogger.error('MQTT connection failed', e, stackTrace);
      client.disconnect();
      return false;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      _connected = true;
      _subscribeToTelemetry();
      onConnectionChanged?.call(true);
      return true;
    }
    return false;
  }

  void _handleIncomingMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      final payload = msg.payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(
        payload.payload.message,
      );
      try {
        final json = jsonDecode(message);
        final telemetry = TelemetryModel.fromJson(
          Map<String, dynamic>.from(json as Map),
          deviceId: deviceId,
        );
        onTelemetryReceived(telemetry);
      } catch (e, stackTrace) {
        AppLogger.error('Failed to parse telemetry payload', e, stackTrace);
      }
    }
  }

  CommandDispatchResult sendCommand(Map<String, dynamic> command) {
    final client = _client;
    if (!_connected || client == null) {
      return const CommandDispatchResult.unavailable(
        'Broker MQTT belum terhubung.',
      );
    }

    try {
      final topic = settings.commandTopicFor(deviceId);
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(command));
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      AppLogger.info('Command sent to $topic: $command');
      return const CommandDispatchResult.sent(
        'Perintah berhasil dikirim ke broker.',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to publish command', e, stackTrace);
      return const CommandDispatchResult.unavailable(
        'Perintah gagal dikirim ke broker.',
      );
    }
  }

  CommandDispatchResult sendPumpSpray(int durationSec) {
    return sendCommand(FirmwareProtocol.buildPumpSprayCommand(durationSec));
  }

  CommandDispatchResult updateSchedule(int startHour, int endHour) {
    if (!FirmwareProtocol.isValidSchedule(startHour, endHour)) {
      return const CommandDispatchResult.invalid(
        'Jadwal tidak valid. Firmware hanya mendukung rentang jam dalam hari yang sama.',
      );
    }

    return sendCommand(
      FirmwareProtocol.buildScheduleCommand(startHour, endHour),
    );
  }

  void disconnect() {
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _subscribedTopic = null;
    if (_connected) {
      _client?.disconnect();
    }
    _connected = false;
  }

  void _subscribeToTelemetry() {
    final client = _client;
    if (client == null) {
      return;
    }

    final topic = settings.telemetryTopicFor(deviceId);
    if (_subscribedTopic != topic) {
      client.subscribe(topic, MqttQos.atMostOnce);
      _subscribedTopic = topic;
      AppLogger.info('MQTT subscribed: $topic');
    }

    _updatesSubscription ??= client.updates?.listen(_handleIncomingMessage);
  }

  void _handleConnected() {
    _connected = true;
    _subscribeToTelemetry();
    AppLogger.info('MQTT connected');
    onConnectionChanged?.call(true);
  }

  void _handleDisconnected() {
    _connected = false;
    _subscribedTopic = null;
    AppLogger.info('MQTT disconnected');
    onConnectionChanged?.call(false);
  }
}
