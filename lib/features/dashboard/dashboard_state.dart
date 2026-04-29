part of 'dashboard_cubit.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardConnected extends DashboardState {}
class DashboardDataUpdated extends DashboardState {
  final TelemetryModel telemetry;
  final DateTime lastSeen;
  const DashboardDataUpdated({required this.telemetry, required this.lastSeen});
  @override
  List<Object?> get props => [telemetry, lastSeen];
}
class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}