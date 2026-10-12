import 'dart:async';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/chat_signalr_service.dart';
import '../../domain/repositories/chat_repository.dart';
import 'conversation_list_event.dart';
import 'conversation_list_state.dart';

class ConversationListBloc extends Bloc<ConversationListEvent, ConversationListState> {
  final ChatRepository _repository;
  final ChatSignalRService _signalRService;

  StreamSubscription? _messageSubscription;

  ConversationListBloc(this._repository, this._signalRService) : super(ConversationListInitial()) {
    on<ConversationListRequested>(_onRequested);
    on<ConversationListMessageReceived>(_onRequested);

    _messageSubscription = _signalRService.messageStream.listen((_) {
      add(ConversationListMessageReceived());
    });
  }

  Future<void> _onRequested(
    ConversationListEvent event,
    Emitter<ConversationListState> emit,
  ) async {
    if (event is ConversationListRequested) emit(ConversationListLoading());
    try {
      final result = await _repository.getConversations();
      emit(ConversationListLoaded(result.items));
    } catch (e) {
      if (event is ConversationListRequested) {
        emit(ConversationListError(mapErrorToMessage(e)));
      }
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
