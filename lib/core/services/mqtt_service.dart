import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import '../../models/telemetry_model.dart';
import '../utils/logger.dart';

class MqttService {
  final String deviceId;
  final Function(TelemetryModel) onTelemetryReceived;
  late MqttServerClient client;
  bool _connected = false;

  MqttService({required this.deviceId, required this.onTelemetryReceived});

  Future<bool> connect() async {
    client = MqttServerClient('broker.hivemq.com', 'flutter_$deviceId');
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 60;
    client.onConnected = () => AppLogger.info('MQTT connected');
    client.onDisconnected = () {
      _connected = false;
      AppLogger.info('MQTT disconnected');
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_$deviceId')
        .startClean();
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      AppLogger.error('MQTT connection failed: $e');
      return false;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      _connected = true;
      final topicTelemetry = 'tanisolution/$deviceId/telemetry';
      client.subscribe(topicTelemetry, MqttQos.atMostOnce);
      client.updates?.listen(_handleIncomingMessage);
      return true;
    }
    return false;
  }

  void _handleIncomingMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (var msg in messages) {
      final payload = msg.payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
      try {
        final json = jsonDecode(message);
        final telemetry = TelemetryModel.fromJson(json);
        onTelemetryReceived(telemetry);
      } catch (e) {
        AppLogger.error('Failed to parse telemetry: $e');
      }
    }
  }

  void sendCommand(Map<String, dynamic> command) {
    if (!_connected) return;
    final topic = 'tanisolution/$deviceId/command';
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(command));
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    AppLogger.info('Command sent: $command');
  }

  void sendPump(int durationSec) {
    sendCommand({'pump_action': 'ON', 'duration_sec': durationSec});
  }

  void sendUvSchedule(int startHour, int endHour) {
    sendCommand({'uv_start': startHour, 'uv_stop': endHour});
  }

  void disconnect() {
    if (_connected) client.disconnect();
  }
}