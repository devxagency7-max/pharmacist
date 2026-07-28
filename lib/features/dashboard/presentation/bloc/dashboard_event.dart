abstract class DashboardEvent {}

class DashboardLoadRequested extends DashboardEvent {
  final String pharmacyId;
  DashboardLoadRequested(this.pharmacyId);
}
