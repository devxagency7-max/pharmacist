import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/network/paged_result.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_state.dart';
import 'package:pharmacist/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:pharmacist/features/chat/domain/repositories/chat_repository.dart';
import 'package:pharmacist/features/chat/domain/entities/chat_entity.dart';
import 'package:pharmacist/features/reports/presentation/screens/reports_screen.dart';
import 'package:pharmacist/features/ratings/domain/repositories/rating_repository.dart';
import 'package:pharmacist/features/ratings/domain/entities/rating_entity.dart';
import 'package:pharmacist/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:pharmacist/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pharmacist/features/notifications/domain/entities/notification_entity.dart';
import 'package:pharmacist/features/patients/domain/repositories/patient_repository.dart';
import 'package:pharmacist/features/patients/domain/entities/patient_entity.dart';
import 'package:pharmacist/features/patients/presentation/screens/patient_detail_screen.dart';
import 'package:pharmacist/features/patients/presentation/screens/patients_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharmacist/core/widgets/app_avatar.dart';
import 'package:pharmacist/core/widgets/app_drawer.dart';

/// Rebranded Home Screen following 36-Point Visual Branding Protocol
/// Apple HIG Glassmorphism, Uniform Accent Palette, Clean Typography
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Real data loaded from API
  int _unreadNotificationsCount = 0;
  int _activeChatsCount = 0;
  double _averageRating = 0;
  int _ratingsCount = 0;
  List<NotificationEntity> _recentNotifications = [];
  List<PatientSummaryEntity> _myPatients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch live data concurrently
      final authState = context.read<AuthBloc>().state;
      final pharmacistId = authState is AuthAuthenticated ? authState.user.id : null;

      final futures = await Future.wait([
        getIt<NotificationRepository>().getUnreadCount(),
        getIt<ChatRepository>().getConversations(page: 1, pageSize: 50),
        getIt<NotificationRepository>().getNotifications(page: 1, pageSize: 5),
        getIt<PatientRepository>().getMyPatients(page: 1, pageSize: 15),
        if (pharmacistId != null)
          getIt<RatingRepository>().getPharmacistRatings(pharmacistId, page: 1, pageSize: 50),
      ]);

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = futures[0] as int;
          _activeChatsCount = (futures[1] as PagedResult<ConversationEntity>).items.length;
          _recentNotifications = (futures[2] as PagedResult<NotificationEntity>).items;
          _myPatients = (futures[3] as PagedResult<PatientSummaryEntity>).items;
          if (pharmacistId != null) {
            final ratings = (futures[4] as PagedResult<RatingEntity>).items;
            _ratingsCount = ratings.length;
            _averageRating = ratings.isEmpty
                ? 0
                : ratings.map((r) => r.score).reduce((a, b) => a + b) / ratings.length;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل البيانات الحية: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} د';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} س';
    } else {
      return 'منذ ${diff.inDays} يوم';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic name from AuthBloc
    final authState = context.watch<AuthBloc>().state;
    
    if (authState is AuthAuthenticated) {
      debugPrint('👤 HOME USER DATA: name="${authState.user.name}", email="${authState.user.email}", roles=${authState.user.roles}');
    } else {
      debugPrint('👤 HOME AUTH STATE: $authState');
    }

    String pharmacistName = 'صيدلي';
    if (authState is AuthAuthenticated) {
      final name = authState.user.name.trim();
      if (name.isNotEmpty) {
        pharmacistName = name.startsWith('د.') ? name : 'د. $name';
      } else {
        final firebaseName = getIt<FirebaseAuth>().currentUser?.displayName?.trim();
        if (firebaseName != null && firebaseName.isNotEmpty) {
          pharmacistName = firebaseName.startsWith('د.') ? firebaseName : 'د. $firebaseName';
        }
      }
    }

    return Scaffold(
      drawerScrimColor: Colors.transparent,
      endDrawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildAmbientMeshBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: _loadData,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                        strokeWidth: 3,
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorWidget()
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 16.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Builder(
                                  builder: (headerContext) => _buildHeader(headerContext),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: _buildAppleGlassDoctorGreetingCard(pharmacistName),
                              ),
                              SizedBox(height: 24.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Text(
                                  'الوصول السريع',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              _buildActionCardsHorizontalList(context),
                              SizedBox(height: 24.h),
                              
                              // My Active Patients section
                              _buildMyPatientsSection(),

                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: _buildSectionTitle('أحدث التنبيهات والنشاطات'),
                              ),
                              SizedBox(height: 12.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: _buildActivityList(),
                              ),
                              SizedBox(height: 32.h),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 44),
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              label: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Ambient background mesh matching the 36-Point Spec (Level 0 depth)
  Widget _buildAmbientMeshBackground() {
    return Stack(
      children: [
        Positioned(
          top: -80.h,
          right: -80.w,
          child: Container(
            width: 260.r,
            height: 260.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 200.h,
          left: -60.w,
          child: Container(
            width: 220.r,
            height: 220.r,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.05),
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

  /// Header Bar: App Logo + Title "طمني" on Right, Side Drawer Menu Icon Button on Left
  Widget _buildHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Logo & Clean Title "طمنّي" (Right side in RTL)
          Row(
            children: [
              Image.asset(
                'assets/images/logo_icon_app-removebg-preview.png',
                width: 38.w,
                height: 38.w,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 8.w),
              Text(
                'طمنّي',
                style: GoogleFonts.cairo(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Side Drawer Icon Button (Left side in RTL)
          GestureDetector(
            onTap: () => Scaffold.of(context).openEndDrawer(),
            child: _buildSoftGlassCard(
              padding: EdgeInsets.all(9.r),
              borderRadius: BorderRadius.circular(12.r),
              child: Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 22.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Apple HIG Style Liquid Frosted Glass Doctor Greeting Card with Uniform Color Tint
  Widget _buildAppleGlassDoctorGreetingCard(String pharmacistName) {
    return FadeInUp(
      duration: const Duration(milliseconds: 450),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                // Uniform primary brand color tint for clean Apple HIG glass appearance
                color: AppColors.primary.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أهلاً بك، $pharmacistName 👋',
                    style: GoogleFonts.cairo(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'نتمنى لك يوماً سعيداً ومثمراً في خدمة ورعاية المرضى 🩺✨',
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Action Rail Cards List View (Level 1, Sleek 16.r Radii)
  Widget _buildActionCardsHorizontalList(BuildContext context) {
    final actions = [
      {
        'title': 'المحادثات',
        'value': '$_activeChatsCount',
        'unit': 'نشطة',
        'icon': Icons.chat_bubble_outline_rounded,
        'color': const Color(0xFFF39C12),
        'screen': const ChatListScreen()
      },
      {
        'title': 'الإشعارات ',
        'value': '$_unreadNotificationsCount',
        'unit': 'تنبيه',
        'icon': Icons.notifications_none_rounded,
        'color': const Color(0xFFFF4757),
        'screen': const NotificationsScreen()
      },
      {
        'title': "التقييمات",
        'value': '$_ratingsCount',
        'unit': 'تقييم',
        'icon': Icons.star_rounded,
        'color': const Color(0xFF9B59B6),
        'screen': const ReportsScreen()
      },
    ];

    return SizedBox(
      height: 135.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: actions.length,
        separatorBuilder: (context, index) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final action = actions[index];
          return FadeInUp(
            delay: Duration(milliseconds: 70 * index),
            duration: const Duration(milliseconds: 350),
            child: _buildVerticalCard(
              context: context,
              title: action['title'] as String,
              value: action['value'] as String,
              unit: action['unit'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              screen: action['screen'] as Widget,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalCard({
    required BuildContext context,
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
      child: _buildSoftGlassCard(
        width: 120.w,
        padding: EdgeInsets.all(12.r),
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  unit,
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 11.5.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: color, size: 18.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Active Patients Horizontal Section (Sleek 16.r Radii)
  Widget _buildMyPatientsSection() {
    if (_myPatients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مرضاي النشطين 👥',
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PatientsScreen()),
                  );
                },
                child: Text(
                  'عرض الكل',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 92.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _myPatients.length,
            separatorBuilder: (context, index) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final p = _myPatients[index];
              return FadeInRight(
                delay: Duration(milliseconds: 50 * index),
                duration: const Duration(milliseconds: 350),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailScreen(patientId: p.patientId),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryGreen, width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.14),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AppAvatar(
                          avatarUrl: p.avatarUrl,
                          name: p.name,
                          radius: 26.r,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      SizedBox(
                        width: 72.w,
                        child: Text(
                          p.name,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// Activity List View (Level 1 Cards, Sleek 16.r Radii)
  Widget _buildActivityList() {
    if (_recentNotifications.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1D26).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primaryGreen,
                  size: 32.r,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'كل شيء منظم تماماً 🎉',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                'لا توجد تنبيهات جديدة تتطلب اتخاذ إجراء حالياً',
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentNotifications.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = _recentNotifications[index];
        return FadeInRight(
          delay: Duration(milliseconds: 80 + (index * 70)),
          duration: const Duration(milliseconds: 350),
          child: _buildActivityItem(
            title: item.title,
            subtitle: item.body,
            time: _getRelativeTime(item.createdAt),
            type: item.type,
          ),
        );
      },
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required String type,
  }) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'order':
        icon = Icons.shopping_bag_outlined;
        color = AppColors.primaryGreen;
        break;
      case 'prescription':
        icon = Icons.receipt_long_rounded;
        color = AppColors.primary;
        break;
      case 'chat':
        icon = Icons.chat_bubble_outline_rounded;
        color = const Color(0xFFF39C12);
        break;
      default:
        icon = Icons.notifications_none_rounded;
        color = const Color(0xFF9B59B6);
    }

    return _buildSoftGlassCard(
      padding: EdgeInsets.all(14.r),
      borderRadius: BorderRadius.circular(16.r),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
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
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            time,
            style: GoogleFonts.cairo(
              fontSize: 11.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for building ultra-soft elevated glass containers
  Widget _buildSoftGlassCard({
    required Widget child,
    required EdgeInsetsGeometry padding,
    required BorderRadius borderRadius,
    double? width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D26).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
