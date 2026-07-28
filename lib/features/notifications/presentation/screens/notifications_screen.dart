import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

/// Notifications inbox (backend Module G: GET /notifications,
/// GET /notifications/unread-count, PUT /notifications/{id}/read).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<NotificationBloc>()..add(NotificationsRequested()),
      child: const _NotificationsView(),
    );
  }
}

enum _FilterTab { all, unread }

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  _FilterTab _selectedTab = _FilterTab.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            _buildHeader(context),
            SizedBox(height: 20.h),
            _buildTabBar(context),
            SizedBox(height: 12.h),
            Expanded(
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationsLoading || state is NotificationInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is NotificationsError) {
                    return _buildErrorState(context, state.message);
                  }
                  if (state is NotificationsLoaded) {
                    final items = _selectedTab == _FilterTab.unread
                        ? state.items.where((n) => !n.isRead).toList()
                        : state.items;
                    if (items.isEmpty) {
                      return _buildEmptyState();
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<NotificationBloc>().add(NotificationsRequested());
                        await context.read<NotificationBloc>().stream.firstWhere(
                              (s) => s is NotificationsLoaded || s is NotificationsError,
                            );
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) => _NotificationCard(notification: items[index]),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'الإشعارات',
            style: GoogleFonts.cairo(fontSize: 24.sp, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const Spacer(),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is! NotificationsLoaded || state.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return Text(
                '${state.unreadCount} غير مقروءة',
                style: GoogleFonts.cairo(fontSize: 13.sp, color: AppColors.primaryGreen, fontWeight: FontWeight.w800),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          _buildTabItem(_FilterTab.all, 'الكل'),
          SizedBox(width: 12.w),
          _buildTabItem(_FilterTab.unread, 'غير مقروءة'),
        ],
      ),
    );
  }

  Widget _buildTabItem(_FilterTab tab, String label) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 64.r, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text(
              'لا توجد إشعارات',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64.r, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(message, style: GoogleFonts.cairo(color: AppColors.textSecondary), textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.read<NotificationBloc>().add(NotificationsRequested()),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(notification.type);
    final color = _colorFor(notification.type);

    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: notification.isRead
          ? null
          : () => context.read<NotificationBloc>().add(NotificationMarkAsReadSubmitted(notification.id)),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: notification.isRead ? Colors.transparent : color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.cairo(
                            fontWeight: notification.isRead ? FontWeight.w700 : FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: GoogleFonts.cairo(fontSize: 13.sp, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _formatRelativeTime(notification.createdAt),
                    style: GoogleFonts.cairo(fontSize: 11.sp, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'OrderUpdate':
        return Icons.receipt_long_rounded;
      case 'PrescriptionUpdate':
        return Icons.description_outlined;
      case 'ChatMessage':
        return Icons.chat_bubble_outline_rounded;
      case 'SystemAlert':
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'SystemAlert':
        return AppColors.error;
      case 'PrescriptionUpdate':
        return AppColors.primaryGreen;
      default:
        return AppColors.primary;
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}
