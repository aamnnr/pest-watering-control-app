part of 'history_cubit.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<TelemetryModel> telemetry;
  final List<ActivityLogEntry> logs;

  const HistoryLoaded({
    required this.telemetry,
    required this.logs,
  });

  @override
  List<Object?> get props => [telemetry, logs];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
