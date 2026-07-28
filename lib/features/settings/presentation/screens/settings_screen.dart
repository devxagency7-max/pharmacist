import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/widgets/custom_widgets.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_event.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedTab = 0;

  final List<String> _tabs = [
    'الملف الشخصي',
    'الإشعارات',
    'الأمان',
    'المظهر',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الاسم مطلوب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20.r),
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
          ProfileUpdateSubmitted(
            name: name,
            phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ التغييرات بنجاح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(20.r),
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(20.r),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _buildBackgroundMesh(),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  _buildHeader(),
                  SizedBox(height: 20.h),
                  _buildTabSwitcher(),
                  Expanded(
                    child: _buildTabContent(),
                  ),
                ],
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: FadeInDown(
        duration: const Duration(milliseconds: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'الإعدادات',
                  style: GoogleFonts.cairo(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(right: 50.w),
              child: Text(
                'إدارة حسابك وتفضيلات التطبيق الخاصة بك بسهولة',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return FadeInUp(
      child: Container(
        height: 50.h,
        margin: EdgeInsets.symmetric(vertical: 10.h),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: _tabs.length,
          separatorBuilder: (context, index) => SizedBox(width: 12.w),
          itemBuilder: (context, index) {
            bool isSelected = _selectedTab == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? AppColors.primaryGreen.withOpacity(0.3) : Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _tabs[index],
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildProfileTab();
      default:
        return Center(
          child: FadeInUp(
            child: _buildGlassContainer(
              padding: EdgeInsets.all(20.r),
              child: Text(
                'قريباً: ${_tabs[_selectedTab]}',
                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildProfileTab() {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المعلومات الشخصية',
              style: GoogleFonts.cairo(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            SizedBox(height: 16.h),

            _buildGlassTextField('الاسم', 'أدخل اسمك', controller: _nameController),
            SizedBox(height: 16.h),

            _buildGlassTextField(
              'البريد الإلكتروني',
              'email@example.com',
              icon: Icons.email_outlined,
              controller: _emailController,
              isPoppins: true,
              readOnly: true,
            ),
            SizedBox(height: 16.h),

            _buildGlassTextField(
              'رقم الهاتف',
              '+20 100 000 0000',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              isPoppins: true,
            ),

            SizedBox(height: 40.h),

            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isSaving = state is AuthLoading;
                return CustomPrimaryButton(
                  label: isSaving ? 'جارِ الحفظ...' : 'حفظ التغييرات',
                  onPressed: _onSavePressed,
                  isLoading: isSaving,
                  color: AppColors.primaryGreen,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField(
    String label,
    String hint, {
    IconData? icon,
    TextEditingController? controller,
    bool isPoppins = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        _buildGlassContainer(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            style: isPoppins
                ? GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
                    fontSize: 14.sp,
                  )
                : GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
                    fontSize: 14.sp,
                  ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 13.sp, fontWeight: FontWeight.bold),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.primaryGreen) : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child, required EdgeInsetsGeometry padding}) {
    return Container(
      padding: padding,
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
          child: child,
        ),
      ),
    );
  }
}
