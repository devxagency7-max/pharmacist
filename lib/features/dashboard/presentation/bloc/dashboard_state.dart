import '../../domain/entities/dashboard_entities.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardDataEntity data;
  DashboardLoaded(this.data);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
