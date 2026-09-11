import 'package:pharmacist/core/network/paged_result.dart';
import '../entities/chat_entity.dart';

abstract class ChatRepository {
  /// GET /chat/conversations?page=&pageSize=
  Future<PagedResult<ConversationEntity>> getConversations({
    int page = 1,
    int pageSize = 20,
  });

  /// POST /chat/conversations — starts or finds a conversation.
  Future<ConversationEntity> startConversation({
    required String otherParticipantId,
    String? relatedOrderId,
  });

  /// GET /chat/{id}/messages?cursor=&pageSize=50 — cursor-paginated.
  Future<CursorPagedResult<MessageEntity>> getMessages(
    String conversationId, {
    String? cursor,
    int pageSize = 50,
  });

  /// POST /chat/{id}/messages
  Future<MessageEntity> sendMessage(
    String conversationId, {
    required String content,
    String messageType = 'Text',
  });

  /// PUT /chat/conversations/{id}/read
  Future<void> markConversationRead(String conversationId);

  /// POST /chat/ai-message — general-purpose AI assistant chat
  /// (Pharmacist-only; any other role gets 403). [conversationId] threads
  /// consecutive sends into the same AI conversation so the backend can
  /// include the last 20 messages as context — omit it for the first
  /// message. [patientId] is optional: when set, the reply is grounded in
  /// that patient's data, but requires an Active care relationship with
  /// them (403 if not, 404 if the patient doesn't exist).
  Future<MessageEntity> sendAiMessage(
    String message, {
    String? conversationId,
    String? patientId,
  });
}
