import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/features/medication_plans/presentation/screens/medication_plan_form_screen.dart';

class PatientMedicationPlansScreen extends StatelessWidget {
  final List<dynamic> plans;
  final String patientId;
  final String patientName;

  const PatientMedicationPlansScreen({
    super.key,
    required this.plans,
    required this.patientId,
    required this.patientName,
  });

  Future<void> _openEdit(BuildContext context, Map<String, dynamic> plan) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationPlanFormScreen(
          patientId: patientId,
          patientName: patientName,
          existingPlan: plan,
        ),
      ),
    );
    if (updated == true && context.mounted) {
      // Pop back to patient detail so it refreshes with the latest plans.
      Navigator.pop(context, true);
    }
  }

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
                  child: plans.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          physics: const BouncingScrollPhysics(),
                          itemCount: plans.length,
                          separatorBuilder: (context, index) => SizedBox(height: 16.h),
                          itemBuilder: (context, index) {
                            final plan = plans[index] as Map<String, dynamic>;
                            return FadeInUp(
                              delay: Duration(milliseconds: 50 * index),
                              child: _buildPlanCard(context, plan),
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
              color: const Color(0xFF00E676).withOpacity(0.12),
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
              color: const Color(0xFF29B6F6).withOpacity(0.12),
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
              color: const Color(0xFFFF8A65).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
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
                    'الخطة الدوائية العلاجية',
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
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
            Icon(Icons.medication_rounded, size: 64.r, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text(
              'لا توجد خطة دوائية نشطة لهذا المريض',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Map<String, dynamic> plan) {
    final medicineName = plan['medicineName'] as String? ?? 'دواء غير معروف';
    final dosage = plan['dosage'] as String? ?? '';
    final instructions = plan['instructions'] as String? ?? '';
    final schedules = plan['schedules'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: EdgeInsets.all(18.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Medicine info
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medication_liquid_rounded,
                        color: AppColors.primaryGreen,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicineName,
                            style: GoogleFonts.cairo(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (dosage.isNotEmpty)
                            Text(
                              'الجرعة: $dosage',
                              style: GoogleFonts.cairo(
                                fontSize: 13.sp,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20.r),
                      tooltip: 'تعديل الخطة',
                      onPressed: () => _openEdit(context, plan),
                    ),
                  ],
                ),
                if (instructions.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التعليمات الإرشادية:',
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          instructions,
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (schedules.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Text(
                    'أوقات التذكير والجرعات:',
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...schedules.map((schedule) => _buildScheduleItem(schedule)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule) {
    final timeStr = schedule['timeOfDay'] as String? ?? '';
    final freq = schedule['frequency'] as String? ?? '';
    final startStr = schedule['startDate'] as String? ?? '';
    final endStr = schedule['endDate'] as String? ?? '';

    // Convert frequency to Arabic
    String arabicFreq = freq;
    if (freq.toLowerCase() == 'daily') {
      arabicFreq = 'يومياً';
    } else if (freq.toLowerCase() == 'weekly') {
      arabicFreq = 'أسبوعياً';
    } else if (freq.toLowerCase() == 'monthly') {
      arabicFreq = 'شهرياً';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.alarm_rounded, color: const Color(0xFFF39C12), size: 18.r),
              SizedBox(width: 8.w),
              Text(
                timeStr,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  arabicFreq,
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (startStr.isNotEmpty)
            Row(
              children: [
                Icon(Icons.date_range_rounded, color: AppColors.textSecondary, size: 14.r),
                SizedBox(width: 4.w),
                Text(
                  endStr.isNotEmpty ? '$startStr إلى $endStr' : 'بدءاً من $startStr',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
