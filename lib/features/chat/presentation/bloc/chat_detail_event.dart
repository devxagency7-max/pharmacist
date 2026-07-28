import '../../domain/entities/chat_entity.dart';

abstract class ChatDetailEvent {}

class ChatMessagesRequested extends ChatDetailEvent {}

class ChatMessageSendSubmitted extends ChatDetailEvent {
  final String content;
  ChatMessageSendSubmitted(this.content);
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
