import '../../domain/entities/chat_entity.dart';

abstract class ChatDetailState {}

class ChatDetailInitial extends ChatDetailState {}

class ChatDetailLoading extends ChatDetailState {}

class ChatDetailLoaded extends ChatDetailState {
  final List<MessageEntity> messages;
  final bool sending;
  final bool isClosed;
  final String? nextCursor;
  final bool hasMore;
  final bool loadingMore;
  // Transient: set when a send fails for a reason other than the
  // conversation being closed, so the screen can surface it once (e.g. as a
  // SnackBar) instead of failing silently.
  final String? sendError;

  ChatDetailLoaded(
    this.messages, {
    this.sending = false,
    this.isClosed = false,
    this.nextCursor,
    this.hasMore = false,
    this.loadingMore = false,
    this.sendError,
  });

  ChatDetailLoaded copyWith({
    List<MessageEntity>? messages,
    bool? sending,
    bool? isClosed,
    String? nextCursor,
    bool? hasMore,
    bool? loadingMore,
    String? sendError,
  }) {
    return ChatDetailLoaded(
      messages ?? this.messages,
      sending: sending ?? this.sending,
      isClosed: isClosed ?? this.isClosed,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      // Not `?? this.sendError` on purpose: this is a one-shot event, not
      // sticky state — every emit must explicitly pass it (or leave it
      // null) rather than it lingering from a previous failed send.
      sendError: sendError,
    );
  }
}

class ChatDetailError extends ChatDetailState {
  final String message;
  ChatDetailError(this.message);
}
