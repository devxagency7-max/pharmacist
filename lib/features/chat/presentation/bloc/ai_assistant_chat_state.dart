import '../../domain/entities/chat_entity.dart';

class AiAssistantChatState {
  final List<MessageEntity> messages;
  final String? conversationId;
  final bool isLoadingHistory;
  final bool isSending;
  final String? errorMessage;

  AiAssistantChatState({
    this.messages = const [],
    this.conversationId,
    this.isLoadingHistory = false,
    this.isSending = false,
    this.errorMessage,
  });

  AiAssistantChatState copyWith({
    List<MessageEntity>? messages,
    String? conversationId,
    bool? isLoadingHistory,
    bool? isSending,
    String? errorMessage,
  }) {
    return AiAssistantChatState(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}
