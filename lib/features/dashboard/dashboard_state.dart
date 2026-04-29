part of 'dashboard_cubit.dart';

enum DashboardConnectionStatus {
  initial,
  connecting,
  connected,
  disconnected,
  error,
}

class DashboardState extends Equatable {
  final DeviceModel device;
  final TelemetryModel? telemetry;
  final DashboardConnectionStatus connectionStatus;
  final bool isOffline;
  final String? errorMessage;
  final List<ActivityLogEntry> recentLogs;

  const DashboardState({
    required this.device,
    required this.telemetry,
    required this.connectionStatus,
    required this.isOffline,
    required this.errorMessage,
    required this.recentLogs,
  });

  factory DashboardState.initial({
    required DeviceModel device,
    TelemetryModel? telemetry,
    required bool isOffline,
    required List<ActivityLogEntry> recentLogs,
  }) {
    return DashboardState(
      device: device,
      telemetry: telemetry,
      connectionStatus: DashboardConnectionStatus.initial,
      isOffline: isOffline,
      errorMessage: null,
      recentLogs: recentLogs,
    );
  }

  int get batteryPercent => telemetry?.bat ?? device.lastBattery;

  bool get isUvOn => telemetry?.isUvOn ?? false;

  bool get isPumpOn => telemetry?.isPumpOn ?? false;

  String get scheduleSummary => device.scheduleLabel;

  DashboardState copyWith({
    DeviceModel? device,
    TelemetryModel? telemetry,
    DashboardConnectionStatus? connectionStatus,
    bool? isOffline,
    String? errorMessage,
    List<ActivityLogEntry>? recentLogs,
    bool clearError = false,
  }) {
    return DashboardState(
      device: device ?? this.device,
      telemetry: telemetry ?? this.telemetry,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }

  @override
  List<Object?> get props => [
        device,
        telemetry,
        connectionStatus,
        isOffline,
        errorMessage,
        recentLogs,
      ];
}
