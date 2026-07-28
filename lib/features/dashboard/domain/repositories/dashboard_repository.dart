import '../entities/dashboard_entities.dart';

abstract class DashboardRepository {
  Future<DashboardDataEntity> getDashboardData({
    required String pharmacyId,
  });
}
