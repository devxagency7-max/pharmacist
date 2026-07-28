import 'package:pharmacist/core/network/paged_result.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  /// GET /notifications?page=&pageSize=20 — paginated, newest first.
  Future<PagedResult<NotificationEntity>> getNotifications({
    int page = 1,
    int pageSize = 20,
  });

  /// GET /notifications/unread-count
  Future<int> getUnreadCount();

  /// PUT /notifications/{id}/read
  Future<void> markAsRead(String notificationId);
}
