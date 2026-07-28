import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';

class HealthReadingsScreen extends StatelessWidget {
  const HealthReadingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackgroundMesh(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        _buildChartPlaceholder(),
                        SizedBox(height: 24.h),
                        _buildReadingsList(),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: FadeInDown(
        duration: const Duration(milliseconds: 600),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'السجلات الصحية',
                  style: GoogleFonts.cairo(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryGreen,
                size: 28.r,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return FadeInDown(
      child: Container(
        width: double.infinity,
        height: 180.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.primaryGreen,
                      size: 48.r,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'رسم بياني للنشاط الصحي',
                    style: GoogleFonts.cairo(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'سيظهر ملخص نشاطك هنا قريباً',
                    style: GoogleFonts.cairo(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
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

  Widget _buildReadingsList() {
    final readings = [
      {
        'type': 'ضغط الدم',
        'value': '120/80',
        'date': 'اليوم، 10:30 AM',
        'status': 'طبيعي',
        'icon': Icons.favorite,
      },
      {
        'type': 'مستوى السكر',
        'value': '95',
        'date': 'أمس، 08:00 PM',
        'status': 'طبيعي',
        'icon': Icons.bloodtype,
      },
      {
        'type': 'الوزن',
        'value': '75 كجم',
        'date': '20 أبريل',
        'status': 'مستقر',
        'icon': Icons.monitor_weight,
      },
      {
        'type': 'ضربات القلب',
        'value': '72',
        'date': '19 أبريل',
        'status': 'طبيعي',
        'icon': Icons.monitor_heart,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: readings.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final reading = readings[index];
        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: _buildReadingCard(
            title: reading['type'] as String,
            value: reading['value'] as String,
            date: reading['date'] as String,
            status: reading['status'] as String,
            icon: reading['icon'] as IconData,
          ),
        );
      },
    );
  }

  Widget _buildReadingCard({
    required String title,
    required String value,
    required String date,
    required String status,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24.r),
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
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(icon, color: AppColors.primaryGreen, size: 24.r),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      _buildTimeText(date),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildValueText(value),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeText(String text) {
    // Regex for time patterns like "10:30 AM" or dates like "20"
    final pattern = RegExp(r'(\d+:\d+|\d+)');
    final match = pattern.firstMatch(text);

    if (match != null) {
      final numberPart = match.group(0)!;
      final before = text.substring(0, match.start);
      final after = text.substring(match.end);
      return RichText(
        text: TextSpan(
          children: [
            if (before.isNotEmpty)
              TextSpan(
                text: before,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            TextSpan(
              text: numberPart,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (after.isNotEmpty)
              TextSpan(
                text: after,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      );
    }

    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 12.sp,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildValueText(String value) {
    // Regex for numbers in values like "120/80" or "75"
    final pattern = RegExp(r'(\d+/\d+|\d+)');
    final match = pattern.firstMatch(value);

    if (match != null) {
      final numberPart = match.group(0)!;
      final before = value.substring(0, match.start);
      final after = value.substring(match.end);
      return RichText(
        text: TextSpan(
          children: [
            if (before.isNotEmpty)
              TextSpan(
                text: before,
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
            TextSpan(
              text: numberPart,
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (after.isNotEmpty)
              TextSpan(
                text: after,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      );
    }

    return Text(
      value,
      style: GoogleFonts.cairo(
        fontSize: 18.sp,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryGreen,
      ),
    );
  }
}
