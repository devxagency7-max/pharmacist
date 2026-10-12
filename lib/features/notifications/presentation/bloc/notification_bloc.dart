import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  NotificationBloc(this._repository) : super(NotificationInitial()) {
    on<NotificationsRequested>(_onNotificationsRequested);
    on<NotificationMarkAsReadSubmitted>(_onMarkAsReadSubmitted);
    on<UnreadCountRequested>(_onUnreadCountRequested);
  }

  Future<void> _onNotificationsRequested(
    NotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationsLoading());
    try {
      final results = await Future.wait([
        _repository.getNotifications(),
        _repository.getUnreadCount(),
      ]);
      final page = results[0] as dynamic;
      final unreadCount = results[1] as int;
      emit(NotificationsLoaded(page.items, unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationsError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onMarkAsReadSubmitted(
    NotificationMarkAsReadSubmitted event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;

    // Optimistic local update first, then re-sync from the server.
    final updatedItems = current.items
        .map((n) => n.id == event.notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    final wasUnread = current.items.any((n) => n.id == event.notificationId && !n.isRead);
    emit(current.copyWith(
      items: updatedItems,
      unreadCount: wasUnread ? (current.unreadCount - 1).clamp(0, 1 << 30) : current.unreadCount,
    ));

    try {
      await _repository.markAsRead(event.notificationId);
      final freshCount = await _repository.getUnreadCount();
      if (state is NotificationsLoaded) {
        emit((state as NotificationsLoaded).copyWith(unreadCount: freshCount));
      }
    } catch (e) {
      // Revert to the pre-optimistic state on failure.
      emit(current);
    }
  }

  Future<void> _onUnreadCountRequested(
    UnreadCountRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    try {
      final count = await _repository.getUnreadCount();
      emit((state as NotificationsLoaded).copyWith(unreadCount: count));
    } catch (_) {
      // Silent — this is a background refresh, not a user-initiated action.
    }
  }
}
