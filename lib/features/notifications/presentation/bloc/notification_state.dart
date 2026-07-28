import '../../domain/entities/notification_entity.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationsLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<NotificationEntity> items;
  final int unreadCount;
  NotificationsLoaded(this.items, {this.unreadCount = 0});

  NotificationsLoaded copyWith({List<NotificationEntity>? items, int? unreadCount}) {
    return NotificationsLoaded(items ?? this.items, unreadCount: unreadCount ?? this.unreadCount);
  }
}

class NotificationsError extends NotificationState {
  final String message;
  NotificationsError(this.message);
}
