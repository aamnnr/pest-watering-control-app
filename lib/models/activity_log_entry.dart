import 'package:equatable/equatable.dart';

enum ActivityLogType {
  telemetry,
  command,
  system,
  alert,
}

class ActivityLogEntry extends Equatable {
  final ActivityLogType type;
  final DateTime timestamp;
  final String title;
  final String detail;
  final String? deviceId;

  const ActivityLogEntry({
    required this.type,
    required this.timestamp,
    required this.title,
    required this.detail,
    this.deviceId,
  });

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      type: ActivityLogType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => ActivityLogType.system,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      title: json['title'] as String? ?? 'Aktivitas',
      detail: json['detail'] as String? ?? '',
      deviceId: json['deviceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'detail': detail,
      'deviceId': deviceId,
    };
  }

  @override
  List<Object?> get props => [type, timestamp, title, detail, deviceId];
}
