import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import 'package:pharmacist/core/network/paged_result.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepositoryImpl(this._apiClient);

  @override
  Future<PagedResult<NotificationEntity>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return unwrapApiResponse(
      response,
      (json) => PagedResult.fromJson(json, NotificationModel.fromJson),
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get(ApiConstants.notificationsUnreadCount);
    return unwrapApiResponse(response, (json) => json as int);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.dio.put(ApiConstants.notificationRead(notificationId));
  }
}
