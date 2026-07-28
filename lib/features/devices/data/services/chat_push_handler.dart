import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pharmacist/core/services/local_notifications_service.dart';
import 'package:pharmacist/features/chat/domain/repositories/chat_repository.dart';
import 'package:pharmacist/features/chat/presentation/screens/chat_detail_screen.dart';

/// Must be a top-level (or static) function per the firebase_messaging
/// contract — the OS may invoke it in a separate isolate while the app is
/// fully backgrounded/terminated. Nothing to do here yet: FCM itself already
/// renders the system notification for a data+notification payload when the
/// app isn't running; this hook exists for cases where we'd need to react to
/// a data-only payload in the background (e.g. silently updating local
/// state), which we don't do today.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Shows a local notification for chat push messages that arrive while the
/// app is in the foreground (FCM does not auto-display those — only
/// background/terminated notifications get the OS tray treatment
/// automatically), and deep-links a tap on a background/terminated
/// notification straight to the relevant conversation.
///
/// Payload shape (confirmed with backend): `{type, referenceId,
/// referenceType}` — `referenceId`/`referenceType` are generic across all
/// notification kinds (Order, Conversation, MedicationPlan...), not chat
/// specific, and are omitted entirely (not empty strings) when absent.
class ChatPushHandler {
  final LocalNotificationsService _localNotifications;
  final ChatRepository _chatRepository;
  final GlobalKey<NavigatorState> _navigatorKey;

  static const _chatDetailRouteName = '/chat-detail';

  ChatPushHandler(
    this._localNotifications,
    this._chatRepository,
    this._navigatorKey,
  );

  Future<void> init() async {
    await _localNotifications.init();
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.showNotification(
      id: message.hashCode,
      title: notification.title ?? 'رسالة جديدة',
      body: notification.body ?? '',
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final conversationId = _conversationIdFrom(message.data);
    if (conversationId == null) return;
    unawaited(_openConversation(conversationId));
  }

  String? _conversationIdFrom(Map<String, dynamic> data) {
    if (data['type'] != 'ChatMessage' ||
        data['referenceType'] != 'Conversation') {
      return null;
    }
    final referenceId = data['referenceId'] as String?;
    return (referenceId != null && referenceId.isNotEmpty) ? referenceId : null;
  }

  /// The push payload only carries the conversationId — the pharmacist
  /// screen also needs the patient's name and id (for the read-only AI
  /// tab), so we resolve those from the conversations list. A freshly
  /// pushed message just updated this conversation's lastMessageAt, and the
  /// list is sorted desc by that, so it's virtually guaranteed to be on the
  /// first page.
  Future<void> _openConversation(String conversationId) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    // A ChatDetailScreen for this exact conversation may already be open
    // (e.g. the pharmacist is mid-conversation when this notification is
    // tapped). Pushing another one would spin up a second ChatDetailBloc
    // subscribed to the same singleton ChatSignalRService, so every
    // incoming message gets delivered — and rendered — twice. If one is
    // already on the stack for the same conversationId, just surface it
    // instead of stacking a duplicate. A push for a *different*
    // conversation should still open normally.
    bool foundExisting = false;
    navigator.popUntil((route) {
      if (route.settings.name == '$_chatDetailRouteName/$conversationId') {
        foundExisting = true;
      }
      return true;
    });
    if (foundExisting) return;
    try {
      final result = await _chatRepository.getConversations();
      for (final conversation in result.items) {
        if (conversation.id == conversationId) {
          navigator.push(
            MaterialPageRoute(
              settings: RouteSettings(
                name: '$_chatDetailRouteName/$conversationId',
              ),
              builder: (_) => ChatDetailScreen(
                conversationId: conversation.id,
                otherParticipantName: conversation.otherParticipantName,
                patientId: conversation.otherParticipantId,
                conversationStatus: conversation.status,
              ),
            ),
          );
          return;
        }
      }
      debugPrint(
        '📩 Chat notification: conversation $conversationId not found in first page',
      );
    } catch (e) {
      debugPrint('⚠️ ChatPushHandler: failed to open conversation: $e');
    }
  }
}
