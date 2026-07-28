abstract class ConversationListEvent {}

class ConversationListRequested extends ConversationListEvent {}

/// Fired when a SignalR message arrives for any conversation while this
/// bloc is alive, so the list's lastMessageAt/ordering stays live without
/// requiring the user to pull-to-refresh.
class ConversationListMessageReceived extends ConversationListEvent {}
