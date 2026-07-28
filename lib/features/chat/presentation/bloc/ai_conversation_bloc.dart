import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/api_exception.dart';
import '../../domain/repositories/chat_repository.dart';
import 'ai_conversation_event.dart';
import 'ai_conversation_state.dart';

/// Read-only view of a patient's AI-assistant conversation
/// (GET /pharmacists/patients/{patientId}/ai-conversation). No SignalR —
/// per the backend contract this is a static, cursor-paginated snapshot
/// with no reply capability and no read-state side effects.
class AiConversationBloc extends Bloc<AiConversationEvent, AiConversationState> {
  final ChatRepository _repository;
  final String patientId;

  AiConversationBloc(this._repository, this.patientId) : super(AiConversationInitial()) {
    on<AiConversationRequested>(_onRequested);
    on<AiConversationOlderMessagesRequested>(_onOlderRequested);
  }

  Future<void> _onRequested(
    AiConversationRequested event,
    Emitter<AiConversationState> emit,
  ) async {
    emit(AiConversationLoading());
    try {
      final result = await _repository.getPatientAiConversation(patientId);
      final oldestFirst = result.items.reversed.toList();
      emit(AiConversationLoaded(
        oldestFirst,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        emit(AiConversationNotStarted());
      } else {
        emit(AiConversationError(e is ApiException ? e.message : e.toString()));
      }
    }
  }

  Future<void> _onOlderRequested(
    AiConversationOlderMessagesRequested event,
    Emitter<AiConversationState> emit,
  ) async {
    final current = state;
    if (current is! AiConversationLoaded) return;
    if (!current.hasMore || current.loadingMore || current.nextCursor == null) return;

    emit(current.copyWith(loadingMore: true));
    try {
      final result = await _repository.getPatientAiConversation(patientId, cursor: current.nextCursor);
      final olderOldestFirst = result.items.reversed.toList();
      emit(current.copyWith(
        messages: [...olderOldestFirst, ...current.messages],
        loadingMore: false,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      ));
    } catch (_) {
      emit(current.copyWith(loadingMore: false));
    }
  }
}
