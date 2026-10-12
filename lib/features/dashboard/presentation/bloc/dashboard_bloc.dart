import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardBloc(this._dashboardRepository) : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadDashboard);
  }

  Future<void> _onLoadDashboard(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final data = await _dashboardRepository.getDashboardData(pharmacyId: event.pharmacyId);
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError(mapErrorToMessage(e)));
    }
  }
}
