abstract class NotificationEvent {}

class NotificationsRequested extends NotificationEvent {}

class NotificationMarkAsReadSubmitted extends NotificationEvent {
  final String notificationId;
  NotificationMarkAsReadSubmitted(this.notificationId);
}

class UnreadCountRequested extends NotificationEvent {}
