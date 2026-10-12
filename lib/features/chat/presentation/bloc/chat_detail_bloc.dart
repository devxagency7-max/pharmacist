import 'dart:async';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/network/file_upload_service.dart';
import '../../data/services/chat_signalr_service.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_detail_event.dart';
import 'chat_detail_state.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final ChatRepository _repository;
  final ChatSignalRService _signalRService;
  final FileUploadService _fileUploadService;
  final String conversationId;
  final bool initialIsClosed;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _conversationReadSubscription;

  ChatDetailBloc(
    this._repository,
    this._signalRService,
    this._fileUploadService,
    this.conversationId, {
    this.initialIsClosed = false,
  }) : super(ChatDetailInitial()) {
    on<ChatMessagesRequested>(_onMessagesRequested);
    on<ChatMessageSendSubmitted>(_onSendSubmitted);
    on<ChatImageMessageSubmitted>(_onImageSubmitted);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatConversationReadReceived>(_onConversationReadReceived);
    on<ChatOlderMessagesRequested>(_onOlderMessagesRequested);
    on<ChatMessagesRefreshRequested>(_onMessagesRefreshRequested);

    _initSignalR();
  }

  void _initSignalR() {
    _messageSubscription = _signalRService.messageStream.listen((message) {
      if (message.conversationId == conversationId) {
        add(ChatMessageReceived(message));
      }
    });

    _conversationReadSubscription = _signalRService.conversationReadStream
        .listen((event) {
          if (event.conversationId == conversationId) {
            add(ChatConversationReadReceived(event.userId));
          }
        });
  }

  Future<void> _onMessagesRequested(
    ChatMessagesRequested event,
    Emitter<ChatDetailState> emit,
  ) async {
    emit(ChatDetailLoading());
    await _signalRService.connect();
    await _signalRService.joinConversation(conversationId);
    try {
      final result = await _repository.getMessages(conversationId);
      await _repository.markConversationRead(conversationId);
      // Backend returns newest-first; the UI list is kept oldest-first so
      // that new messages can simply be appended at the end.
      final oldestFirst = result.items.reversed.toList();
      emit(
        ChatDetailLoaded(
          oldestFirst,
          isClosed: initialIsClosed,
          nextCursor: result.nextCursor,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      emit(ChatDetailError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onSendSubmitted(
    ChatMessageSendSubmitted event,
    Emitter<ChatDetailState> emit,
  ) async {
    final current = state;
    if (current is! ChatDetailLoaded) return;

    emit(current.copyWith(sending: true));

    try {
      final sent = await _repository.sendMessage(
        conversationId,
        content: event.content,
      );
      // Re-read state instead of reusing `current`: flutter_bloc's default
      // transformer runs event handlers concurrently, so a message could
      // have arrived via SignalR (_onMessageReceived) while this REST call
      // was in flight. Building off the stale `current` would silently
      // drop that message when this emit overwrites it.
      final latest = state;
      if (latest is! ChatDetailLoaded) return;
      // That same SignalR echo could have already appended this exact
      // message (via _onMessageReceived) before this REST response came
      // back — the two race, and whichever arrives second must not
      // duplicate the bubble the first one already added.
      final alreadyAdded =
          sent.id.isNotEmpty && latest.messages.any((m) => m.id == sent.id);
      emit(
        latest.copyWith(
          messages: alreadyAdded
              ? latest.messages
              : [...latest.messages, sent],
          sending: false,
        ),
      );
    } catch (e) {
      // Backend contract: a Closed conversation is the only case that sets
      // errorCode "CONVERSATION_CLOSED" — a stable, language-independent
      // signal, unlike matching on the free-form (and Arabic-first) message
      // text.
      final isClosed =
          asApiException(e)?.errorCode == 'CONVERSATION_CLOSED';
      final latest = state;
      if (latest is! ChatDetailLoaded) return;
      emit(
        latest.copyWith(
          sending: false,
          isClosed: isClosed ? true : latest.isClosed,
          // Only surface a generic error when it's not the closed-conversation
          // case — that has its own dedicated banner/disabled composer.
          sendError: isClosed
              ? null
              : mapErrorToMessage(e),
        ),
      );
    }
  }

  Future<void> _onImageSubmitted(
    ChatImageMessageSubmitted event,
    Emitter<ChatDetailState> emit,
  ) async {
    final current = state;
    if (current is! ChatDetailLoaded) return;

    emit(current.copyWith(uploadingImage: true));

    try {
      final uploaded = await _fileUploadService.uploadFile(
        filePath: event.filePath,
        fileType: 'ChatAttachment',
      );
      final sent = await _repository.sendMessage(
        conversationId,
        content: uploaded.url,
        messageType: 'Image',
      );
      // Same staleness/dedup concern as _onSendSubmitted: state may have
      // moved on (e.g. a SignalR echo already appended this message) while
      // the upload + send were in flight.
      final latest = state;
      if (latest is! ChatDetailLoaded) return;
      final alreadyAdded =
          sent.id.isNotEmpty && latest.messages.any((m) => m.id == sent.id);
      emit(
        latest.copyWith(
          messages: alreadyAdded
              ? latest.messages
              : [...latest.messages, sent],
          uploadingImage: false,
        ),
      );
    } catch (e) {
      final isClosed =
          asApiException(e)?.errorCode == 'CONVERSATION_CLOSED';
      final latest = state;
      if (latest is! ChatDetailLoaded) return;
      emit(
        latest.copyWith(
          uploadingImage: false,
          isClosed: isClosed ? true : latest.isClosed,
          sendError: isClosed
              ? null
              : mapErrorToMessage(e),
        ),
      );
    }
  }

  Future<void> _onMessagesRefreshRequested(
    ChatMessagesRefreshRequested event,
    Emitter<ChatDetailState> emit,
  ) async {
    final current = state;
    if (current is! ChatDetailLoaded) return;

    try {
      final result = await _repository.getMessages(conversationId);
      await _repository.markConversationRead(conversationId);
      final oldestFirst = result.items.reversed.toList();

      // Re-read state: SignalR could have appended a live message (or the
      // conversation could have closed) while this REST call was in flight.
      final latest = state;
      if (latest is! ChatDetailLoaded) return;

      // Merge instead of replacing outright: keep any locally-known messages
      // (e.g. an optimistic send still in flight) that this fetched page
      // doesn't yet include, while de-duping by id against the fresh page.
      final freshIds = oldestFirst.map((m) => m.id).toSet();
      final onlyLocal = latest.messages
          .where((m) => m.id.isEmpty || !freshIds.contains(m.id))
          .toList();

      emit(
        latest.copyWith(
          messages: [...oldestFirst, ...onlyLocal],
          nextCursor: result.nextCursor,
          hasMore: result.hasMore,
        ),
      );
    } catch (_) {
      // Silent failure: a pull-to-refresh that fails just leaves the
      // existing list as-is rather than surfacing an error banner.
    }
  }

  Future<void> _onOlderMessagesRequested(
    ChatOlderMessagesRequested event,
    Emitter<ChatDetailState> emit,
  ) async {
    final current = state;
    if (current is! ChatDetailLoaded) return;
    if (!current.hasMore || current.loadingMore || current.nextCursor == null)
      return;

    emit(current.copyWith(loadingMore: true));
    try {
      final result = await _repository.getMessages(
        conversationId,
        cursor: current.nextCursor,
      );
      final olderOldestFirst = result.items.reversed.toList();
      // Same staleness concern as _onSendSubmitted above: re-read state so a
      // message that arrived while this pagination request was in flight
      // isn't dropped from the emitted list.
      final latest = state;
      if (latest is! ChatDetailLoaded) return;
      emit(
        latest.copyWith(
          messages: [...olderOldestFirst, ...latest.messages],
          loadingMore: false,
          nextCursor: result.nextCursor,
          hasMore: result.hasMore,
        ),
      );
    } catch (_) {
      final latest = state;
      if (latest is! ChatDetailLoaded) return;
      emit(latest.copyWith(loadingMore: false));
    }
  }

  void _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatDetailState> emit,
  ) {
    final current = state;
    if (current is ChatDetailLoaded) {
      // An empty id (missing from the payload) must never dedup-match
      // another message — otherwise every id-less message after the first
      // would be silently treated as a duplicate and dropped.
      final isDuplicateById =
          event.message.id.isNotEmpty &&
          current.messages.any((m) => m.id == event.message.id);
      // Defensive fallback: if the backend ever emits ReceiveMessage twice
      // for the same logical message under two different ids, id-based dedup
      // above won't catch it. Treat same sender + same content arriving
      // within a couple seconds of an existing message as the same message.
      final isDuplicateByContent = current.messages.any(
        (m) =>
            event.message.senderId.isNotEmpty &&
            m.senderId == event.message.senderId &&
            m.content == event.message.content &&
            (m.createdAt.difference(event.message.createdAt)).abs() <
                const Duration(seconds: 3),
      );
      if (!isDuplicateById && !isDuplicateByContent) {
        emit(current.copyWith(messages: [...current.messages, event.message]));
      }
    }
  }

  void _onConversationReadReceived(
    ChatConversationReadReceived event,
    Emitter<ChatDetailState> emit,
  ) {
    final current = state;
    if (current is ChatDetailLoaded) {
      final updated = current.messages
          .map(
            (m) => m.senderId != event.userId && !m.isRead
                ? m.copyWith(isRead: true)
                : m,
          )
          .toList();
      emit(current.copyWith(messages: updated));
    }
  }

  @override
  Future<void> close() async {
    await _signalRService.leaveConversation(conversationId);
    _messageSubscription?.cancel();
    _conversationReadSubscription?.cancel();
    return super.close();
  }
}
