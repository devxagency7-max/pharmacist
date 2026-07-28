import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepositoryImpl(this._apiClient);

  @override
  Future<DashboardDataEntity> getDashboardData({required String pharmacyId}) async {
    final params = {'pharmacyId': pharmacyId};

    final futures = await Future.wait([
      _apiClient.dio.get(ApiConstants.dashboardMetrics, queryParameters: params),
      _apiClient.dio.get(ApiConstants.dashboardOrderDistribution, queryParameters: params),
      _apiClient.dio.get(ApiConstants.dashboardFulfillmentTrend, queryParameters: {...params, 'months': 6}),
      _apiClient.dio.get(ApiConstants.dashboardTopMedications, queryParameters: {...params, 'limit': 5}),
      _apiClient.dio.get(ApiConstants.dashboardRejectionNotes, queryParameters: {...params, 'limit': 5}),
    ]);

    final metricsJson = unwrapApiResponse(futures[0], (json) => json as Map<String, dynamic>);
    final distJson = unwrapApiResponse(futures[1], (json) => json as Map<String, dynamic>);
    final trendList = unwrapApiResponse(futures[2], (json) => json as List);
    final topMedList = unwrapApiResponse(futures[3], (json) => json as List);
    final rejectList = unwrapApiResponse(futures[4], (json) => json as List);

    return DashboardDataEntity(
      metrics: DashboardMetricsEntity(
        totalOrders: metricsJson['totalOrders'] ?? 0,
        pendingOrders: metricsJson['pendingOrders'] ?? 0,
        completedOrders: metricsJson['completedOrders'] ?? 0,
        successRate: metricsJson['successRate'] != null
            ? (metricsJson['successRate'] as num).toDouble()
            : 0.0,
      ),
      distribution: OrderDistributionEntity(
        withPrescription: distJson['withPrescription'] ?? 0,
        withoutPrescription: distJson['withoutPrescription'] ?? 0,
      ),
      trend: trendList
          .map((item) => FulfillmentTrendEntity(
                year: item['year'] ?? 0,
                month: item['month'] ?? 0,
                completedCount: item['completedCount'] ?? 0,
              ))
          .toList(),
      topMedications: topMedList
          .map((item) => TopMedicationEntity(
                medicineId: item['medicineId'] ?? '',
                name: item['name'] ?? '',
                orderItemCount: item['orderItemCount'] ?? 0,
              ))
          .toList(),
      rejectionNotes: rejectList
          .map((item) => RejectionNoteEntity(
                orderId: item['orderId'] ?? '',
                reason: item['reason'] ?? item['comments'] ?? 'غير محدد',
              ))
          .toList(),
    );
  }
}
