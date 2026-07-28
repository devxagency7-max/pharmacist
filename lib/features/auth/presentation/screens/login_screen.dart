import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/features/auth/domain/entities/user_entity.dart';
import 'package:pharmacist/features/auth/domain/repositories/auth_repository.dart';
import 'package:pharmacist/features/auth/presentation/screens/application_status_screen.dart';
import 'package:pharmacist/features/home/presentation/screens/main_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthenticatedUser(BuildContext context, UserEntity user) async {
    final roles = user.roles;
    if (roles.contains('Pharmacist') ||
        roles.contains('PharmacyIntern') ||
        roles.contains('PharmacyOwner')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
      return;
    }

    try {
      final application = await getIt<AuthRepository>().getApplicationStatus();
      if (!context.mounted) return;
      if (application != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicationStatusScreen(initialApplication: application),
          ),
        );
        return;
      }
    } catch (_) {}

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpScreen(
          initialName: user.name,
          initialEmail: user.email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _handleAuthenticatedUser(context, state.user);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Stack(
          children: [
            _buildBackgroundMesh(),
            SafeArea(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                'مرحباً بك مجدداً',
                                style: GoogleFonts.cairo(
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: _buildGlassTextField(
                                controller: _emailController,
                                label: 'البريد الإلكتروني',
                                hint: 'example@mail.com',
                                icon: Icons.email_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 14.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 300),
                              child: _buildGlassTextField(
                                controller: _passwordController,
                                label: 'كلمة المرور',
                                hint: '********',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
                                  return null;
                                },
                              ),
                            ),
                            
                            SizedBox(height: 8.h),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'نسيت كلمة المرور؟',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 20.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 400),
                              child: BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return Column(
                                    children: [
                                      _buildGlassButton(
                                        label: state is AuthLoading ? 'جاري التحميل...' : 'تسجيل الدخول',
                                        onPressed: state is AuthLoading ? () {} : () {
                                          if (_formKey.currentState!.validate()) {
                                            context.read<AuthBloc>().add(
                                              LoginSubmitted(
                                                email: _emailController.text.trim(),
                                                password: _passwordController.text,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      SizedBox(height: 12.h),
                                      _buildDivider(),
                                      SizedBox(height: 12.h),
                                      _buildGoogleButton(
                                        isLoading: state is AuthLoading,
                                        onPressed: () {
                                          context.read<AuthBloc>().add(GoogleSignInSubmitted());
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            
                            SizedBox(height: 20.h),
                            
                            FadeInUp(
                              delay: const Duration(milliseconds: 500),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'ليس لديك حساب؟ ',
                                    style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14.sp, fontWeight: FontWeight.w600),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                      );
                                    },
                                    child: Text(
                                      'إنشاء حساب جديد',
                                      style: GoogleFonts.cairo(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    ),
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
        Positioned(
          top: -100.h,
          right: -100.w,
          child: Container(
            width: 300.r,
            height: 300.r,
            decoration: BoxDecoration(
              color: const Color(0xFFB3E5FC).withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 200.h,
          left: -50.w,
          child: Container(
            width: 250.r,
            height: 250.r,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE6DC).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 100.h,
          right: -50.w,
          child: Container(
            width: 280.r,
            height: 280.r,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFF5).withOpacity(0.5),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 200.h,
      alignment: Alignment.center,
      child: FadeInDown(
        duration: const Duration(milliseconds: 800),
        child: Image.asset(
          'assets/images/logo.png',
          width: 120.w,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: GoogleFonts.cairo(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextFormField(
                controller: controller,
                obscureText: isPassword,
                validator: validator,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14.sp),
                  prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 22.r),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({required String label, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 60.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, Color(0xFF2ECC71)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'أو',
            style: GoogleFonts.cairo(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3), thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleButton({required VoidCallback onPressed, bool isLoading = false}) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 58.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google.png',
                  width: 24.w,
                  height: 24.h,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.red.shade600,
                    size: 32.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  isLoading ? 'جاري الاتصال بـ Google...' : 'متابعة باستخدام Google',
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
