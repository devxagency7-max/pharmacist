import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';

/// GET /pharmacists/patients/{id} → `healthReadings` (last 20 readings).
class HealthReadingsScreen extends StatelessWidget {
  final List<dynamic> readings;
  final String patientName;

  const HealthReadingsScreen({
    super.key,
    required this.readings,
    required this.patientName,
  });

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
                  child: readings.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          physics: const BouncingScrollPhysics(),
                          itemCount: readings.length,
                          separatorBuilder: (context, index) => SizedBox(height: 14.h),
                          itemBuilder: (context, index) {
                            final reading = readings[index] as Map<String, dynamic>;
                            return FadeInUp(
                              delay: Duration(milliseconds: 50 * index),
                              child: _buildReadingCard(reading),
                            );
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
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'القراءات الصحية',
                    style: GoogleFonts.cairo(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'ملف المريض: $patientName',
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            Icon(Icons.monitor_heart_rounded, size: 64.r, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text(
              'لا توجد قراءات صحية مسجلة لهذا المريض',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingCard(Map<String, dynamic> reading) {
    final type = reading['type'] as String? ?? 'قراءة';
    final value = reading['value'];
    final notes = reading['notes'] as String?;
    final createdAtStr = reading['createdAt'] as String? ?? '';

    final createdAt = DateTime.tryParse(createdAtStr);
    final dateFormatted = createdAt != null
        ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
        : 'تاريخ غير معروف';

    final arabicType = _getArabicType(type);
    final unit = _getUnit(type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white.withOpacity(0.75), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    _getIcon(type),
                    color: const Color(0xFFE74C3C),
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arabicType,
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12.r, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(
                            dateFormatted,
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (notes != null && notes.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          notes,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (value != null)
                  Text(
                    '$value$unit',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bloodpressure':
        return Icons.favorite_rounded;
      case 'bloodsugar':
      case 'glucose':
        return Icons.water_drop_rounded;
      case 'weight':
        return Icons.monitor_weight_rounded;
      case 'heartrate':
        return Icons.monitor_heart_rounded;
      case 'temperature':
        return Icons.thermostat_rounded;
      default:
        return Icons.health_and_safety_rounded;
    }
  }

  String _getArabicType(String type) {
    switch (type.toLowerCase()) {
      case 'bloodpressure':
        return 'ضغط الدم';
      case 'bloodsugar':
      case 'glucose':
        return 'سكر الدم';
      case 'weight':
        return 'الوزن';
      case 'heartrate':
        return 'معدل ضربات القلب';
      case 'temperature':
        return 'درجة الحرارة';
      default:
        return type;
    }
  }

  String _getUnit(String type) {
    switch (type.toLowerCase()) {
      case 'bloodpressure':
        return ' mmHg';
      case 'bloodsugar':
      case 'glucose':
        return ' mg/dL';
      case 'weight':
        return ' kg';
      case 'heartrate':
        return ' bpm';
      case 'temperature':
        return ' °C';
      default:
        return '';
    }
  }
}
