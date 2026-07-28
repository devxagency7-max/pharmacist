import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15.sp,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextFormField(
                controller: controller,
                obscureText: isPassword,
                validator: validator,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withAlpha(127),
                    fontSize: 14.sp,
                  ),
                  prefixIcon: prefixIcon != null
                      ? Icon(prefixIcon, color: AppColors.primary, size: 22.sp)
                      : null,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isLoading;

  const CustomPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: AppColors.white)
            : Text(
                label,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}

