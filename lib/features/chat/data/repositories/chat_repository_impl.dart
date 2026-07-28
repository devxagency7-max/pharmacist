import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import 'package:pharmacist/core/network/paged_result.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _apiClient;

  ChatRepositoryImpl(this._apiClient);

  @override
  Future<PagedResult<ConversationEntity>> getConversations({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.chatConversations,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return unwrapApiResponse(
      response,
      (json) => PagedResult.fromJson(json, ConversationModel.fromJson),
    );
  }

  @override
  Future<ConversationEntity> startConversation({
    required String otherParticipantId,
    String? relatedOrderId,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.chatConversations,
      data: {
        'otherParticipantId': otherParticipantId,
        if (relatedOrderId != null) 'relatedOrderId': relatedOrderId,
      },
    );
    return unwrapApiResponse(
      response,
      (json) => ConversationModel.fromJson(json),
    );
  }

  @override
  Future<CursorPagedResult<MessageEntity>> getMessages(
    String conversationId, {
    String? cursor,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.chatMessages(conversationId),
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'pageSize': pageSize,
      },
    );
    return unwrapApiResponse(response, (json) {
      final items = (json['items'] as List? ?? [])
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return CursorPagedResult<MessageEntity>(
        items: items,
        nextCursor: json['nextCursor'],
        hasMore: json['hasMore'] as bool? ?? false,
      );
    });
  }

  @override
  Future<MessageEntity> sendMessage(
    String conversationId, {
    required String content,
    String messageType = 'Text',
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.chatMessages(conversationId),
      data: {'content': content, 'messageType': messageType},
    );
    return unwrapApiResponse(response, (json) => MessageModel.fromJson(json));
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    await _apiClient.dio.put(ApiConstants.chatConversationRead(conversationId));
  }

  @override
  Future<CursorPagedResult<MessageEntity>> getPatientAiConversation(
    String patientId, {
    String? cursor,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.patientAiConversation(patientId),
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'pageSize': pageSize,
      },
    );
    return unwrapApiResponse(response, (json) {
      final items = (json['items'] as List? ?? [])
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return CursorPagedResult<MessageEntity>(
        items: items,
        nextCursor: json['nextCursor'],
        hasMore: json['hasMore'] as bool? ?? false,
      );
    });
  }
}
