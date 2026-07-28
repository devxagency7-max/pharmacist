import '../../domain/entities/chat_entity.dart';

abstract class ChatDetailEvent {}

class ChatMessagesRequested extends ChatDetailEvent {}

class ChatMessageSendSubmitted extends ChatDetailEvent {
  final String content;
  ChatMessageSendSubmitted(this.content);
}

class ChatImageMessageSubmitted extends ChatDetailEvent {
  final String filePath;
  ChatImageMessageSubmitted(this.filePath);
}

class ChatMessageReceived extends ChatDetailEvent {
  final MessageEntity message;
  ChatMessageReceived(this.message);
}

class ChatConversationReadReceived extends ChatDetailEvent {
  final String userId;
  ChatConversationReadReceived(this.userId);
}

class ChatOlderMessagesRequested extends ChatDetailEvent {}

/// Pull-to-refresh: re-fetches the newest page without the full-screen
/// loading spinner that ChatMessagesRequested shows on first load.
class ChatMessagesRefreshRequested extends ChatDetailEvent {}
