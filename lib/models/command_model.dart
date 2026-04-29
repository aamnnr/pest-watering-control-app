import 'dart:convert';

class CommandModel {
  final Map<String, dynamic> payload;

  CommandModel.uvOnOff(bool isOn) : payload = {
    'uv_start': isOn ? 0 : 0,
    'uv_stop': isOn ? 24 : 0,
  };

  CommandModel.pumpOn({int durationSec = 10}) : payload = {
    'pump_action': 'ON',
    'duration_sec': durationSec,
  };

  CommandModel.updateSchedule(int startHour, int endHour) : payload = {
    'uv_start': startHour,
    'uv_stop': endHour,
  };

  String toJson() => jsonEncode(payload);
}