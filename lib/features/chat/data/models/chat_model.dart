import '../../domain/entities/chat_entity.dart';

class ConversationModel extends ConversationEntity {
  ConversationModel({
    required super.id,
    required super.otherParticipantId,
    required super.otherParticipantName,
    super.relatedOrderId,
    required super.status,
    super.lastMessageAt,
    required super.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      otherParticipantId: json['otherParticipantId'] ?? '',
      otherParticipantName: json['otherParticipantName'] ?? '',
      relatedOrderId: json['relatedOrderId'],
      status: json['status'] ?? '',
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.tryParse(json['lastMessageAt']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class MessageModel extends MessageEntity {
  MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderName,
    required super.content,
    required super.messageType,
    required super.isRead,
    super.readAt,
    required super.isAI,
    required super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'Text',
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      isAI: json['isAI'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
