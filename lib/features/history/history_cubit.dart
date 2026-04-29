// lib/features/history/history_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/services/storage_service.dart';
import '../../models/telemetry_model.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final StorageService storage;
  HistoryCubit(this.storage) : super(HistoryLoading());

  void loadHistory() {
    final data = storage.getTelemetryHistory();
    emit(HistoryLoaded(data));
  }
}