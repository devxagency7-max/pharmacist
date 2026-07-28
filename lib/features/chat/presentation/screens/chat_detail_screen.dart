import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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

/// Gen Z Rebranded Chat Detail Screen
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
  final _imagePicker = ImagePicker();
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
      body: Stack(
        children: [
          _buildAmbientMeshBackground(),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 12.h),
                _buildHeader(context),
                SizedBox(height: 14.h),
                _buildGenZSegmentedTabBar(),
                SizedBox(height: 12.h),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildPharmacistTab(currentUserId), _buildAiTab()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientMeshBackground() {
    return Stack(
      children: [
        Positioned(
          top: -60.h,
          right: -60.w,
          child: Container(
            width: 240.r,
            height: 240.r,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 100.h,
          left: -80.w,
          child: Container(
            width: 220.r,
            height: 220.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final firstChar = widget.otherParticipantName.isNotEmpty
        ? widget.otherParticipantName[0].toUpperCase()
        : '?';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1D26).withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.r,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Stack(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    firstChar,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 10.r,
                  height: 10.r,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              widget.otherParticipantName,
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenZSegmentedTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 46.h,
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.cairo(fontSize: 12.5.sp, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'التعامل مع المريض 💬'),
            Tab(text: 'سجل المساعد AI 🤖'),
          ],
        ),
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
          SnackBar(
            content: Text(message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => _refreshMessages(context),
              child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
                builder: (context, state) {
                if (state is ChatDetailLoading || state is ChatDetailInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
                  );
                }
                if (state is ChatDetailError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.error_outline_rounded, size: 44.r, color: AppColors.error),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            state.message,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13.5.sp, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is ChatDetailLoaded) {
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.chat_bubble_outline_rounded, size: 48.r, color: AppColors.primaryGreen),
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            'ابدأ المحادثة والاستشارة الآن 💬',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14.sp, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }
                  final itemCount = messages.length + (state.loadingMore ? 1 : 0);
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (state.loadingMore && index == itemCount - 1) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 2),
                          ),
                        );
                      }
                      final message = messages[messages.length - 1 - index];
                      final isMe = message.senderId == currentUserId;
                      return FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: _MessageBubble(message: message, isMe: isMe),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
              ),
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
                  'انتهت هذه المحادثة 🔒',
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

  Widget _buildAiTab() {
    return BlocBuilder<AiConversationBloc, AiConversationState>(
      builder: (context, state) {
        if (state is AiConversationLoading || state is AiConversationInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          );
        }
        if (state is AiConversationNotStarted) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.smart_toy_outlined, size: 48.r, color: Colors.purple),
                ),
                SizedBox(height: 14.h),
                Text(
                  'المريض لم يستخدم المساعد الذكي بعد 🤖',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14.sp, color: AppColors.textPrimary),
                ),
              ],
            ),
          );
        }
        if (state is AiConversationError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Text(
                state.message,
                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
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
                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
              ),
            );
          }
          final itemCount = messages.length + (state.loadingMore ? 1 : 0);
          return ListView.builder(
            controller: _aiScrollController,
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (state.loadingMore && index == itemCount - 1) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.purple, strokeWidth: 2),
                  ),
                );
              }
              final message = messages[messages.length - 1 - index];
              return FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: _MessageBubble(message: message, isMe: false),
              );
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
          builder: (context, state) {
            final sending = state is ChatDetailLoaded && state.sending;
            final uploadingImage = state is ChatDetailLoaded && state.uploadingImage;
            final isClosed = state is ChatDetailLoaded && state.isClosed;
            final busy = sending || uploadingImage;
            return Row(
              children: [
                GestureDetector(
                  onTap: (busy || isClosed) ? null : () => _pickAndSendImage(context),
                  child: Container(
                    width: 46.r,
                    height: 46.r,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A1D26).withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: uploadingImage
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: const CircularProgressIndicator(
                                color: AppColors.primaryGreen,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.image_outlined,
                              color: AppColors.textPrimary,
                              size: 20.r,
                            ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A1D26).withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                    child: TextField(
                      controller: _messageController,
                      enabled: !isClosed,
                      style: GoogleFonts.cairo(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: isClosed
                            ? 'انتهت هذه المحادثة 🔒'
                            : 'اكتب رسالتك هنا...',
                        hintStyle: GoogleFonts.cairo(
                          fontSize: 12.5.sp,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: (busy || isClosed) ? null : () => _send(context),
                  child: Container(
                    width: 46.r,
                    height: 46.r,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: sending
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.send_rounded, color: Colors.white, size: 20.r),
                    ),
                  ),
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

  Future<void> _refreshMessages(BuildContext context) async {
    final bloc = context.read<ChatDetailBloc>();
    final done = bloc.stream.first;
    bloc.add(ChatMessagesRefreshRequested());
    await done;
  }

  Future<void> _pickAndSendImage(BuildContext context) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    context.read<ChatDetailBloc>().add(ChatImageMessageSubmitted(picked.path));
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
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        decoration: BoxDecoration(
          color: message.isAI
              ? Colors.purple.withValues(alpha: 0.12)
              : isMe
              ? AppColors.primaryGreen
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14.r),
            topRight: Radius.circular(14.r),
            bottomLeft: Radius.circular(isMe ? 2.r : 14.r),
            bottomRight: Radius.circular(isMe ? 14.r : 2.r),
          ),
          border: Border.all(
            color: message.isAI
                ? Colors.purple.withValues(alpha: 0.3)
                : isMe
                ? AppColors.primaryGreen
                : Colors.white,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isAI)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy_rounded, size: 14.r, color: Colors.purple),
                    SizedBox(width: 4.w),
                    Text(
                      'رد تلقائي من مساعد طمني الذكي 🤖',
                      style: GoogleFonts.cairo(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            if (message.isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.network(
                  message.content,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_rounded,
                    color: isMe && !message.isAI
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              )
            else
              Text(
                message.content,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  color: isMe && !message.isAI
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            if (isMe)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14.r,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

