import '../../domain/entities/chat_entity.dart';

abstract class ConversationListState {}

class ConversationListInitial extends ConversationListState {}

class ConversationListLoading extends ConversationListState {}

class ConversationListLoaded extends ConversationListState {
  final List<ConversationEntity> items;
  ConversationListLoaded(this.items);
}

class ConversationListError extends ConversationListState {
  final String message;
  ConversationListError(this.message);
}
