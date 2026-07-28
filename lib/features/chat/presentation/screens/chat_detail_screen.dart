import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/chat_entity.dart';
import '../bloc/ai_conversation_bloc.dart';
import '../bloc/ai_conversation_event.dart';
import '../bloc/ai_conversation_state.dart';
import '../bloc/chat_detail_bloc.dart';
import '../bloc/chat_detail_event.dart';
import '../bloc/chat_detail_state.dart';

/// A single conversation's messages (backend Module I:
/// GET /chat/{id}/messages, POST /chat/{id}/messages,
/// PUT /chat/conversations/{id}/read), plus a read-only tab mirroring the
/// patient's separate AI-assistant conversation (Module D extension:
/// GET /pharmacists/patients/{patientId}/ai-conversation).
class ChatDetailScreen extends StatelessWidget {
  final String conversationId;
  final String otherParticipantName;
  final String patientId;
  final String? conversationStatus;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherParticipantName,
    required this.patientId,
    this.conversationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = conversationStatus?.toLowerCase() == 'closed';
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<ChatDetailBloc>(param1: conversationId, param2: isClosed)
                ..add(ChatMessagesRequested()),
        ),
        BlocProvider(
          create: (context) =>
              getIt<AiConversationBloc>(param1: patientId)
                ..add(AiConversationRequested()),
        ),
      ],
      child: _ChatDetailView(otherParticipantName: otherParticipantName),
    );
  }
}

class _ChatDetailView extends StatefulWidget {
  final String otherParticipantName;

  const _ChatDetailView({required this.otherParticipantName});

  @override
  State<_ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<_ChatDetailView>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _aiScrollController = ScrollController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _aiScrollController.addListener(_onAiScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      context.read<ChatDetailBloc>().add(ChatOlderMessagesRequested());
    }
  }

  void _onAiScroll() {
    if (_aiScrollController.position.pixels >=
        _aiScrollController.position.maxScrollExtent - 100) {
      context.read<AiConversationBloc>().add(
        AiConversationOlderMessagesRequested(),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _aiScrollController.removeListener(_onAiScroll);
    _aiScrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          widget.otherParticipantName,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryGreen,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'التعامل مع المريض'),
            Tab(text: 'AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPharmacistTab(currentUserId), _buildAiTab()],
      ),
    );
  }

  String? _currentUserId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.id : null;
  }

  Widget _buildPharmacistTab(String? currentUserId) {
    return BlocListener<ChatDetailBloc, ChatDetailState>(
      listenWhen: (previous, current) =>
          current is ChatDetailLoaded && current.sendError != null,
      listener: (context, state) {
        final message = (state as ChatDetailLoaded).sendError!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message, style: GoogleFonts.cairo())),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
              builder: (context, state) {
                if (state is ChatDetailLoading || state is ChatDetailInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ChatDetailError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Text(
                        state.message,
                        style: GoogleFonts.cairo(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (state is ChatDetailLoaded) {
                  // Show everything in this conversation: the pharmacist's own
                  // replies, the patient's messages, and the AI's auto-fallback
                  // replies (isAI:true) — the fallback happens INSIDE this same
                  // conversation, so filtering it out would hide real activity.
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'ابدأ المحادثة الآن',
                        style: GoogleFonts.cairo(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  final itemCount =
                      messages.length + (state.loadingMore ? 1 : 0);
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.all(16.w),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (state.loadingMore && index == itemCount - 1) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final message = messages[messages.length - 1 - index];
                      final isMe = message.senderId == currentUserId;
                      return _MessageBubble(message: message, isMe: isMe);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          BlocBuilder<ChatDetailBloc, ChatDetailState>(
            builder: (context, state) {
              final isClosed = state is ChatDetailLoaded && state.isClosed;
              if (!isClosed) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                child: Text(
                  'انتهت هذه المحادثة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          _buildComposer(context),
        ],
      ),
    );
  }

  /// Read-only mirror of the patient's separate AI-assistant conversation
  /// (own endpoint, own history — NOT the pharmacist↔patient conversation
  /// and its `isAI` fallback messages). Static snapshot per the backend
  /// contract: no SignalR, no composer, no read-state side effects.
  Widget _buildAiTab() {
    return BlocBuilder<AiConversationBloc, AiConversationState>(
      builder: (context, state) {
        if (state is AiConversationLoading || state is AiConversationInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AiConversationNotStarted) {
          return Center(
            child: Text(
              'المريض لم يستخدم المساعد الذكي بعد',
              style: GoogleFonts.cairo(color: AppColors.textSecondary),
            ),
          );
        }
        if (state is AiConversationError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(
                state.message,
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (state is AiConversationLoaded) {
          final messages = state.messages;
          if (messages.isEmpty) {
            return Center(
              child: Text(
                'لا توجد رسائل بعد',
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
              ),
            );
          }
          final itemCount = messages.length + (state.loadingMore ? 1 : 0);
          return ListView.builder(
            controller: _aiScrollController,
            reverse: true,
            padding: EdgeInsets.all(16.w),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (state.loadingMore && index == itemCount - 1) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final message = messages[messages.length - 1 - index];
              // This is the patient's own AI conversation — the patient is
              // always "them" here, never "me" (the pharmacist never sent
              // anything into it).
              return _MessageBubble(message: message, isMe: false);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildComposer(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
          builder: (context, state) {
            final sending = state is ChatDetailLoaded && state.sending;
            final isClosed = state is ChatDetailLoaded && state.isClosed;
            return Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      controller: _messageController,
                      enabled: !isClosed,
                      style: GoogleFonts.cairo(),
                      decoration: InputDecoration(
                        hintText: isClosed
                            ? 'انتهت هذه المحادثة'
                            : 'اكتب رسالة...',
                        hintStyle: GoogleFonts.cairo(
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: (sending || isClosed)
                      ? null
                      : () => _send(context),
                  icon: sending
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.send_rounded, color: AppColors.primaryGreen),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _send(BuildContext context) {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    context.read<ChatDetailBloc>().add(ChatMessageSendSubmitted(content));
    _messageController.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 0.7.sw),
        decoration: BoxDecoration(
          color: message.isAI
              ? Colors.purple.withValues(alpha: 0.1)
              : isMe
              ? AppColors.primaryGreen
              : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // A faint background tint alone is easy to miss — an explicit
            // label makes sure an AI auto-fallback reply is never mistaken
            // for a message the patient actually sent.
            if (message.isAI)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  'رد تلقائي من المساعد الذكي',
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            Text(
              message.content,
              style: GoogleFonts.cairo(
                color: isMe && !message.isAI
                    ? Colors.white
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isMe)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Icon(
                  message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                  size: 14.r,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
