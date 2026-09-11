import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import '../../domain/entities/chat_entity.dart';
import '../bloc/conversation_list_bloc.dart';
import '../bloc/conversation_list_event.dart';
import '../bloc/conversation_list_state.dart';
import 'chat_detail_screen.dart';

/// Gen Z Rebranded Conversations List Screen
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

class _ChatListView extends StatefulWidget {
  const _ChatListView();

  @override
  State<_ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<_ChatListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                SizedBox(height: 16.h),
                _buildSearchBar(),
                SizedBox(height: 14.h),
                Expanded(
                  child: BlocBuilder<ConversationListBloc, ConversationListState>(
                    builder: (context, state) {
                      if (state is ConversationListLoading || state is ConversationListInitial) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
                        );
                      }
                      if (state is ConversationListError) {
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
                                SizedBox(height: 20.h),
                                ElevatedButton(
                                  onPressed: () => context.read<ConversationListBloc>().add(ConversationListRequested()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                  ),
                                  child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (state is ConversationListLoaded) {
                        var items = state.items
                            .where((c) => c.otherParticipantId != ApiConstants.aiParticipantId)
                            .toList();
                        if (_searchQuery.isNotEmpty) {
                          items = items.where((c) {
                            return c.otherParticipantName.toLowerCase().contains(_searchQuery);
                          }).toList();
                        }

                        if (items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(20.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.chat_bubble_outline_rounded, size: 48.r, color: AppColors.primary),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'لا توجد محادثات تطابق بحثك' : 'لا توجد محادثات بعد 💬',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14.5.sp, color: AppColors.textPrimary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return RefreshIndicator(
                          color: AppColors.primaryGreen,
                          onRefresh: () async {
                            context.read<ConversationListBloc>().add(ConversationListRequested());
                            await context.read<ConversationListBloc>().stream.firstWhere(
                                  (s) => s is ConversationListLoaded || s is ConversationListError,
                                );
                          },
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              return FadeInUp(
                                delay: Duration(milliseconds: 60 * index),
                                duration: const Duration(milliseconds: 350),
                                child: _ConversationTile(conversation: items[index]),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
          top: -80.h,
          left: -80.w,
          child: Container(
            width: 260.r,
            height: 260.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 200.h,
          right: -80.w,
          child: Container(
            width: 240.r,
            height: 240.r,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
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
          Text(
            'المحادثات',
            style: GoogleFonts.cairo(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          // const Spacer(),
          // Container(
          //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          //   decoration: BoxDecoration(
          //     color: AppColors.primary.withValues(alpha: 0.12),
          //     borderRadius: BorderRadius.circular(12.r),
          //     border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(Icons.chat_bubble_outline_rounded, size: 14.r, color: AppColors.primary),
          //       SizedBox(width: 6.w),
          //       Text(
          //         'استشارات حية ⚡',
          //         style: GoogleFonts.cairo(
          //           fontSize: 11.5.sp,
          //           fontWeight: FontWeight.w800,
          //           color: AppColors.primary,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.cairo(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث باسم المريض...',
            hintStyle: GoogleFonts.cairo(
              fontSize: 12.5.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22.r,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18.r, color: AppColors.textSecondary),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final firstChar = conversation.otherParticipantName.isNotEmpty
        ? conversation.otherParticipantName[0].toUpperCase()
        : '?';

    return GestureDetector(
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
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      firstChar,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 11.r,
                    height: 11.r,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherParticipantName,
                          style: GoogleFonts.cairo(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessageAt != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            _formatTime(conversation.lastMessageAt!),
                            style: GoogleFonts.poppins(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'انقر لمتابعة المحادثة والاستشارات 💬',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13.r,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return '${diff.inMinutes} د';
    if (diff.inHours < 24) return '${diff.inHours} س';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

