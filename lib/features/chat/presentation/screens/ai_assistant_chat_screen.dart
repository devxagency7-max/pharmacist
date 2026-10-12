import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/chat_entity.dart';
import '../bloc/ai_assistant_chat_bloc.dart';
import '../bloc/ai_assistant_chat_event.dart';
import '../bloc/ai_assistant_chat_state.dart';

/// General-purpose AI assistant chat for the pharmacist — this is the
/// pharmacist's own conversation with the AI assistant. Optionally scoped to
/// a patient (grounds replies in their data) via [patientId]/[patientName];
/// opened with neither for general drug/medical questions.
class AiAssistantChatScreen extends StatelessWidget {
  final String? patientId;
  final String? patientName;

  const AiAssistantChatScreen({super.key, this.patientId, this.patientName});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isIntern =
        authState is AuthAuthenticated &&
        authState.user.roles.contains('PharmacyIntern') &&
        !authState.user.roles.contains('Pharmacist');

    return BlocProvider(
      create: (context) =>
          getIt<AiAssistantChatBloc>(param1: patientId)
            ..add(AiAssistantHistoryRequested()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _buildAmbientMeshBackground(),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  _buildHeader(context),
                  if (isIntern) ...[
                    SizedBox(height: 8.h),
                    _buildInternDisclaimer(),
                  ],
                  SizedBox(height: 14.h),
                  const Expanded(child: AiAssistantTabView()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInternDisclaimer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.school_rounded, color: Colors.orange, size: 18.r),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'استخدم المساعد الذكي كأداة تعلم. اسأل مشرفك قبل تطبيق أي توصية على مريض.',
                style: GoogleFonts.cairo(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
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
          Container(
            width: 40.r,
            height: 40.r,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20.r,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المساعد الذكي',
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (patientName != null)
                  Text(
                    'بخصوص: $patientName',
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The pharmacist's single, ungrounded conversation with the AI assistant —
/// same conversation regardless of where it's opened from (the home
/// screen's floating button, or as a tab inside a specific patient's chat).
/// Embeddable: no Scaffold/header of its own, so callers place it inside
/// whatever chrome they already have (see [AiAssistantChatScreen] and
/// ChatDetailScreen's AI tab).
class AiAssistantTabView extends StatefulWidget {
  const AiAssistantTabView({super.key});

  @override
  State<AiAssistantTabView> createState() => _AiAssistantTabViewState();
}

class _AiAssistantTabViewState extends State<AiAssistantTabView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildMessages()),
        _buildComposer(context),
      ],
    );
  }

  Widget _buildMessages() {
    return BlocConsumer<AiAssistantChatBloc, AiAssistantChatState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.errorMessage!,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
        );
      },
      builder: (context, state) {
        if (state.isLoadingHistory && state.messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          );
        }
        if (state.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 48.r,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'اسأل المساعد الذكي أي سؤال دوائي أو طبي 🤖',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final messages = state.messages;
        final itemCount = messages.length + (state.isSending ? 1 : 0);
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (state.isSending && index == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }
            final messageIndex = state.isSending ? index - 1 : index;
            final message = messages[messages.length - 1 - messageIndex];
            return FadeInUp(
              duration: const Duration(milliseconds: 300),
              child: _MessageBubble(message: message),
            );
          },
        );
      },
    );
  }

  Widget _buildComposer(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: BlocBuilder<AiAssistantChatBloc, AiAssistantChatState>(
          builder: (context, state) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1A1D26,
                          ).withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 2.h,
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.cairo(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'اكتب سؤالك هنا...',
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
                  onTap: state.isSending ? null : () => _send(context),
                  child: Container(
                    width: 46.r,
                    height: 46.r,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryGreen,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20.r,
                      ),
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
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    context.read<AiAssistantChatBloc>().add(AiAssistantMessageSent(text));
    _messageController.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = !message.isAI;
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryGreen
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14.r),
            topRight: Radius.circular(14.r),
            bottomLeft: Radius.circular(isMe ? 2.r : 14.r),
            bottomRight: Radius.circular(isMe ? 14.r : 2.r),
          ),
          border: Border.all(
            color: isMe
                ? AppColors.primaryGreen
                : AppColors.primary.withValues(alpha: 0.25),
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
            if (!isMe)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_rounded,
                      size: 14.r,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'المساعد الذكي',
                      style: GoogleFonts.cairo(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.content,
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
