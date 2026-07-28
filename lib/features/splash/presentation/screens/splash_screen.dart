import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/features/auth/domain/repositories/auth_repository.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_state.dart';
import 'package:pharmacist/features/auth/presentation/screens/application_status_screen.dart';
import 'package:pharmacist/features/auth/presentation/screens/login_screen.dart';
import 'package:pharmacist/features/auth/presentation/screens/signup_screen.dart';
import 'package:pharmacist/features/home/presentation/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigationScheduled = false;

  void _scheduleNavigation(BuildContext context, AuthState state) {
    if (_navigationScheduled) return;
    if (state is! AuthAuthenticated &&
        state is! AuthUnauthenticated &&
        state is! AuthError) {
      return;
    }
    _navigationScheduled = true;
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      if (state is AuthAuthenticated) {
        final roles = state.user.roles;
        if (roles.contains('Pharmacist') ||
            roles.contains('PharmacyIntern') ||
            roles.contains('PharmacyOwner')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
          return;
        }

        // Not a pharmacist yet — check whether they already have an
        // application in flight before sending them to a fresh sign-up.
        try {
          final application = await getIt<AuthRepository>().getApplicationStatus();
          if (!mounted) return;
          if (application != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ApplicationStatusScreen(initialApplication: application),
              ),
            );
            return;
          }
        } catch (_) {
          // Fall through to sign-up if the status check itself fails.
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignUpScreen()),
        );
      } else if (state is AuthUnauthenticated || state is AuthError) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Handles state changes that arrive *after* this screen subscribes.
      listener: _scheduleNavigation,
      // Also checks the *current* state at build time — AppStarted() is
      // dispatched in main.dart before this screen even mounts, so by the
      // time BlocConsumer subscribes, AuthBloc may already be sitting on a
      // terminal state that a plain BlocListener would never see fire.
      builder: (context, state) {
        _scheduleNavigation(context, state);
        return _buildSplashBody();
      },
    );
  }

  Widget _buildSplashBody() {
    return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _buildBackgroundMesh(),
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  ZoomIn(
                    duration: const Duration(milliseconds: 800),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 180.w,
                      height: 180.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      'Tamenny Pharma',
                      style: GoogleFonts.poppins(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  
                  const Spacer(flex: 2),
                  FadeIn(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildBackgroundMesh() {
    return Stack(
      children: [
        Positioned(
          top: -100.h,
          right: -100.w,
          child: Container(
            width: 400.r,
            height: 400.r,
            decoration: BoxDecoration(
              color: const Color(0xFFB3E5FC).withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}
