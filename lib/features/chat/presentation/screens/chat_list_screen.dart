import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import '../../domain/entities/chat_entity.dart';
import '../bloc/conversation_list_bloc.dart';
import '../bloc/conversation_list_event.dart';
import '../bloc/conversation_list_state.dart';
import 'chat_detail_screen.dart';

/// Conversations list (backend Module I: GET /chat/conversations).
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ConversationListBloc>()..add(ConversationListRequested()),
      child: const _ChatListView(),
    );
  }
}

class _ChatListView extends StatelessWidget {
  const _ChatListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'المحادثات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
      ),
      body: BlocBuilder<ConversationListBloc, ConversationListState>(
        builder: (context, state) {
          if (state is ConversationListLoading || state is ConversationListInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ConversationListError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: GoogleFonts.cairo(color: AppColors.textSecondary), textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => context.read<ConversationListBloc>().add(ConversationListRequested()),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                      child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ConversationListLoaded) {
            if (state.items.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد محادثات بعد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ConversationListBloc>().add(ConversationListRequested());
                await context.read<ConversationListBloc>().stream.firstWhere(
                      (s) => s is ConversationListLoaded || s is ConversationListError,
                    );
              },
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) => _ConversationTile(conversation: state.items[index]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conversation.id,
            otherParticipantName: conversation.otherParticipantName,
            patientId: conversation.otherParticipantId,
            conversationStatus: conversation.status,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
              child: Text(
                conversation.otherParticipantName.isNotEmpty ? conversation.otherParticipantName[0] : '?',
                style: GoogleFonts.poppins(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                conversation.otherParticipantName,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
            if (conversation.lastMessageAt != null)
              Text(
                _formatTime(conversation.lastMessageAt!),
                style: GoogleFonts.poppins(fontSize: 11.sp, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
