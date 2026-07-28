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

  /// GET /pharmacists/patients/{patientId}/ai-conversation?cursor=&pageSize=50
  /// Read-only: the patient's AI-assistant conversation, cursor-paginated,
  /// requires an Active assignment with this patient. 404 if the patient
  /// has never used the AI assistant.
  Future<CursorPagedResult<MessageEntity>> getPatientAiConversation(
    String patientId, {
    String? cursor,
    int pageSize = 50,
  });
}
