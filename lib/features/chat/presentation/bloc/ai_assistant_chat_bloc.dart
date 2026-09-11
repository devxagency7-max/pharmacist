import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/errors/api_exception.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import 'ai_assistant_chat_event.dart';
import 'ai_assistant_chat_state.dart';

/// General-purpose AI assistant chat for the pharmacist (POST
/// /chat/ai-message). Optionally scoped to a patient via [patientId] — when
/// set, the backend grounds replies in that patient's data and requires an
/// Active care relationship with them (403/404 surfaced via
/// [ApiException.statusCode] on [errorMessage]).
///
/// Threads consecutive sends into the same AI conversation by remembering
/// the conversationId returned by the first reply and sending it on every
/// later message — this is what gives the assistant memory (the backend
/// includes the last 20 messages of that conversation as context).
class AiAssistantChatBloc extends Bloc<AiAssistantChatEvent, AiAssistantChatState> {
  final ChatRepository _repository;
  final String? patientId;

  AiAssistantChatBloc(this._repository, {this.patientId}) : super(AiAssistantChatState()) {
    on<AiAssistantHistoryRequested>(_onHistoryRequested);
    on<AiAssistantMessageSent>(_onMessageSent);
  }

  Future<void> _onHistoryRequested(
    AiAssistantHistoryRequested event,
    Emitter<AiAssistantChatState> emit,
  ) async {
    emit(state.copyWith(isLoadingHistory: true, errorMessage: null));
    try {
      final conversations = await _repository.getConversations(pageSize: 50);
      ConversationEntity? aiConversation;
      for (final c in conversations.items) {
        if (c.otherParticipantId == ApiConstants.aiParticipantId) {
          aiConversation = c;
          break;
        }
      }
      if (aiConversation == null) {
        emit(state.copyWith(isLoadingHistory: false));
        return;
      }

      final result = await _repository.getMessages(aiConversation.id);
      // Backend returns newest-first; the UI list is kept oldest-first.
      final oldestFirst = result.items.reversed.toList();
      emit(
        state.copyWith(
          messages: oldestFirst,
          conversationId: aiConversation.id,
          isLoadingHistory: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingHistory: false,
          errorMessage: e is ApiException ? e.message : e.toString(),
        ),
      );
    }
  }

  Future<void> _onMessageSent(
    AiAssistantMessageSent event,
    Emitter<AiAssistantChatState> emit,
  ) async {
    final localMessage = MessageEntity(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: state.conversationId ?? '',
      senderId: '',
      senderName: 'أنت',
      content: event.text,
      messageType: 'Text',
      isRead: true,
      isAI: false,
      createdAt: DateTime.now(),
    );
    emit(
      state.copyWith(
        messages: [...state.messages, localMessage],
        isSending: true,
        errorMessage: null,
      ),
    );

    try {
      final reply = await _repository.sendAiMessage(
        event.text,
        conversationId: state.conversationId,
        patientId: patientId,
      );
      emit(
        state.copyWith(
          messages: [...state.messages, reply],
          conversationId: reply.conversationId,
          isSending: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: e is ApiException ? e.message : e.toString(),
        ),
      );
    }
  }
}
