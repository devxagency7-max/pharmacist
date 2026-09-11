abstract class AiAssistantChatEvent {}

/// Loads the pharmacist's existing AI-assistant conversation history, if
/// any — fired once when the screen opens.
class AiAssistantHistoryRequested extends AiAssistantChatEvent {}

class AiAssistantMessageSent extends AiAssistantChatEvent {
  final String text;

  AiAssistantMessageSent(this.text);
}
