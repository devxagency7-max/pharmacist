class ConversationEntity {
  final String id;
  final String otherParticipantId;
  final String otherParticipantName;
  final String? relatedOrderId;
  final String status;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  ConversationEntity({
    required this.id,
    required this.otherParticipantId,
    required this.otherParticipantName,
    this.relatedOrderId,
    required this.status,
    this.lastMessageAt,
    required this.createdAt,
  });
}

class MessageEntity {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime? readAt;
  final bool isAI;
  final DateTime createdAt;

  MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.isRead,
    this.readAt,
    required this.isAI,
    required this.createdAt,
  });

  bool get isImage => messageType == 'Image';

  MessageEntity copyWith({bool? isRead, DateTime? readAt}) {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      messageType: messageType,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isAI: isAI,
      createdAt: createdAt,
    );
  }
}

/// Cursor-paginated result, matching the backend's `CursorPagedResult<T>`
/// shape used by GET /chat/{id}/messages (cursor/pageSize=50 — distinct
/// from the page/pageSize PagedResult used elsewhere in this app).
class CursorPagedResult<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  CursorPagedResult({required this.items, this.nextCursor, this.hasMore = false});
}
