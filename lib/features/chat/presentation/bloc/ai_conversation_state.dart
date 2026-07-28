import '../../domain/entities/chat_entity.dart';

abstract class AiConversationState {}

class AiConversationInitial extends AiConversationState {}

class AiConversationLoading extends AiConversationState {}

class AiConversationLoaded extends AiConversationState {
  final List<MessageEntity> messages;
  final String? nextCursor;
  final bool hasMore;
  final bool loadingMore;

  AiConversationLoaded(
    this.messages, {
    this.nextCursor,
    this.hasMore = false,
    this.loadingMore = false,
  });

  AiConversationLoaded copyWith({
    List<MessageEntity>? messages,
    String? nextCursor,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return AiConversationLoaded(
      messages ?? this.messages,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Distinguishes "the patient has never used the AI assistant" (backend
/// 404) from a real failure, so the UI can show a friendlier empty state.
class AiConversationNotStarted extends AiConversationState {}

class AiConversationError extends AiConversationState {
  final String message;
  AiConversationError(this.message);
}
