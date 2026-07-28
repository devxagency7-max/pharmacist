import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_state.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_event.dart';
import 'package:pharmacist/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:pharmacist/features/medications/presentation/screens/medications_screen.dart';
import 'package:pharmacist/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:pharmacist/features/reports/presentation/screens/reports_screen.dart';
import 'package:pharmacist/features/settings/presentation/screens/settings_screen.dart';
import 'package:pharmacist/features/auth/presentation/screens/login_screen.dart';
import 'package:pharmacist/features/patients/presentation/screens/patients_screen.dart';
import 'package:pharmacist/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/widgets/app_avatar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final roles = user?.roles ?? [];
    final isOwner = roles.contains('PharmacyOwner');

    return Drawer(
      width: 0.8.sw,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.zero,
          bottomLeft: Radius.zero,
          topRight: Radius.zero,
          bottomRight: Radius.zero,
        ),
        child: Stack(
          children: [
            // Glassmorphism Overlay (Transparent to show background)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), // Much more transparent
                  border: Border(
                    left: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30.h),
                    
                    // User Profile Section
                    _buildProfileSection(context),
                    
                    SizedBox(height: 30.h),
                    Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                    SizedBox(height: 20.h),

                    // Menu Items
                    if (isOwner) ...[
                      _buildDrawerItem(
                        icon: Icons.dashboard_rounded,
                        title: 'لوحة البيانات',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DashboardScreen()),
                          );
                        },
                      ),
                      
                    ] else ...[
                      _buildDrawerItem(
                        icon: Icons.people_alt_rounded,
                        title: 'المرضى',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PatientsScreen()),
                          );
                        },
                      ),
                    ],
                    _buildDrawerItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'المحادثات',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatListScreen()),
                        );
                      },
                    ),
                    if (!isOwner)
                      _buildDrawerItem(
                        icon: Icons.analytics_outlined,
                        title: 'تقييماتي',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportsScreen()),
                          );
                        },
                      ),
                    _buildDrawerItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'التنبيهات',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings_rounded,
                      title: 'الإعدادات',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    
                    const Spacer(),
                    
                    // Logout Button
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'تسجيل الخروج',
                      color: AppColors.error,
                      onTap: () => _showLogoutDialog(context),
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // Version Info
                    Center(
                      child: Text(
                        'الإصدار 1.0.0',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundMesh() {
    return Stack(
      children: [
        // Solid light background base
        Container(color: const Color(0xFFF9FAFB)),
        
        Positioned(
          top: -100.h,
          left: -100.w,
          child: _buildGradientBlob(color: const Color(0xFFB3E5FC).withOpacity(0.3), size: 300.r), // Icy Blue
        ),
        Positioned(
          top: 200.h,
          right: -100.w,
          child: _buildGradientBlob(color: const Color(0xFFFFE6DC).withOpacity(0.6), size: 350.r), // Soft peach
        ),
        Positioned(
          bottom: -50.h,
          left: -50.w,
          child: _buildGradientBlob(color: const Color(0xFFEAEFF5).withOpacity(0.7), size: 300.r), // Gray blue
        ),
        
        // Heavy full-screen blur to melt the colors together
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              color: Colors.white.withOpacity(0.6), // Strong white wash
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBlob({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final firebaseAuth = getIt<FirebaseAuth>();
    final photoUrl = firebaseAuth.currentUser?.photoURL;

    String displayName = 'صيدلي طمنّي';
    if (user != null) {
      final name = user.name.trim();
      if (name.isNotEmpty) {
        displayName = name.startsWith('د.') ? name : 'د. $name';
      } else {
        final firebaseName = firebaseAuth.currentUser?.displayName?.trim();
        if (firebaseName != null && firebaseName.isNotEmpty) {
          displayName = firebaseName.startsWith('د.') ? firebaseName : 'د. $firebaseName';
        }
      }
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppAvatar(
            avatarUrl: photoUrl,
            name: displayName,
            radius: 26.r,
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'صيدلي معتمد',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3), // More transparent for better glass feel
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color ?? AppColors.textPrimary.withOpacity(0.8),
                size: 24.r,
              ),
              SizedBox(width: 16.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary.withOpacity(0.4),
                size: 14.r,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: Text(
            'تسجيل الخروج',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 18.sp),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 14.sp),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
                // Clear stack and navigate to Login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                'خروج',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

