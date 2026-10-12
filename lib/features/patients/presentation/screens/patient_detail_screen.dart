import 'dart:ui';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/widgets/app_avatar.dart';
import 'package:pharmacist/features/chat/data/services/chat_signalr_service.dart';
import 'package:pharmacist/features/chat/domain/repositories/chat_repository.dart';
import 'package:pharmacist/features/chat/presentation/screens/chat_detail_screen.dart';
import '../bloc/patient_bloc.dart';
import '../bloc/patient_event.dart';
import '../bloc/patient_state.dart';
import 'health_readings_screen.dart';
import 'medical_records_screen.dart';
import 'patient_medication_plans_screen.dart';

/// Gen Z Rebranded Patient Detail Screen
class PatientDetailScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<PatientBloc>()..add(PatientDetailRequested(patientId)),
      child: _PatientDetailView(patientId: patientId),
    );
  }
}

class _PatientDetailView extends StatelessWidget {
  final String patientId;

  const _PatientDetailView({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildAmbientMeshBackground(),
          SafeArea(
            child: BlocConsumer<PatientBloc, PatientState>(
              listener: (context, state) {
                if (state is PatientTerminateSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إنهاء العلاقة العلاجية.', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                  );
                  Navigator.pop(context);
                } else if (state is PatientTerminateError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is PatientDetailLoading || state is PatientInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
                  );
                }
                if (state is PatientDetailError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.error_outline_rounded, size: 44.r, color: AppColors.error),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            state.message,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13.5.sp, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is PatientDetailLoaded) {
                  final p = state.patient;
                  return Column(
                    children: [
                      SizedBox(height: 12.h),
                      _buildHeader(context, p.name),
                      SizedBox(height: 16.h),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primaryGreen,
                          onRefresh: () async {
                            context.read<PatientBloc>().add(PatientDetailRequested(patientId));
                            await context.read<PatientBloc>().stream.firstWhere(
                                  (s) => s is PatientDetailLoaded || s is PatientDetailError,
                                );
                          },
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: Column(
                              children: [
                              _buildHeroProfileCard(context, p),
                              SizedBox(height: 16.h),
                              
                              // Health Readings Inline Section
                              _buildHealthReadingsSection(context, p.healthReadings),
                              SizedBox(height: 20.h),
                              
                              // Section Title
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'الملفات والمؤشرات الطبية',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),

                              // Chat action tile
                              FadeInUp(
                                delay: const Duration(milliseconds: 50),
                                child: _buildSectionCard(
                                  title: 'محادثة الاستشارات (شاملة الـ AI)',
                                  subtitle: 'تواصل فوري ومباشر مع المريض',
                                  icon: Icons.chat_bubble_outline_rounded,
                                  iconColor: AppColors.primaryGreen,
                                  badgeText: 'محادثة حية',
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(context);
                                    if (p.conversationId != null) {
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (context) => ChatDetailScreen(
                                            conversationId: p.conversationId!,
                                            otherParticipantName: p.name,
                                            patientId: p.patientId,
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) => const Center(
                                        child: CircularProgressIndicator(color: AppColors.primaryGreen),
                                      ),
                                    );
                                    try {
                                      final conv = await getIt<ChatRepository>()
                                          .startConversation(otherParticipantId: p.patientId);
                                      await getIt<ChatSignalRService>().joinConversation(conv.id);
                                      navigator.pop();
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (context) => ChatDetailScreen(
                                            conversationId: conv.id,
                                            otherParticipantName: p.name,
                                            patientId: p.patientId,
                                            conversationStatus: conv.status,
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(mapErrorToMessage(e))),
                                      );
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: 12.h),

                              FadeInUp(
                                delay: const Duration(milliseconds: 100),
                                child: _buildSectionCard(
                                  title: 'السجلات الطبية للأرشيف',
                                  subtitle: 'عرض الروشتات والمستندات مرفقة',
                                  icon: Icons.folder_open_rounded,
                                  iconColor: AppColors.primary,
                                  badgeText: '${p.medicalRecords.length} سجلات',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MedicalRecordsScreen(
                                        records: p.medicalRecords,
                                        patientName: p.name,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),

                              FadeInUp(
                                delay: const Duration(milliseconds: 150),
                                child: _buildSectionCard(
                                  title: 'خطط الأدوية المعتمدة',
                                  subtitle: 'مواعيد وتنبيهات الجرعات اليومية',
                                  icon: Icons.medication_liquid_rounded,
                                  iconColor: const Color(0xFF9B59B6),
                                  badgeText: '${p.medicationPlans.length} خطط',
                                  onTap: () async {
                                    final updated = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PatientMedicationPlansScreen(
                                          plans: p.medicationPlans,
                                          patientId: p.patientId,
                                          patientName: p.name,
                                        ),
                                      ),
                                    );
                                    if (updated == true && context.mounted) {
                                      context.read<PatientBloc>().add(
                                        PatientDetailRequested(patientId),
                                      );
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: 32.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientMeshBackground() {
    return Stack(
      children: [
        Positioned(
          top: -80.h,
          left: -80.w,
          child: Container(
            width: 260.r,
            height: 260.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 220.h,
          right: -80.w,
          child: Container(
            width: 240.r,
            height: 240.r,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
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

  Widget _buildHeader(BuildContext context, String patientName) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1D26).withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.r,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'ملف المريض',
            style: GoogleFonts.cairo(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _confirmTerminate(context),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(
                Icons.person_remove_alt_1_rounded,
                color: AppColors.error,
                size: 18.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroProfileCard(BuildContext context, dynamic patient) {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 82.r,
                  height: 82.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                AppAvatar(
                  avatarUrl: patient.avatarUrl,
                  name: patient.name,
                  radius: 36.r,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              patient.name,
              style: GoogleFonts.cairo(
                fontSize: 18.5.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              patient.email,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (patient.phone != null && patient.phone!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  patient.phone!,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeroBadge('مريض نشط', AppColors.primaryGreen),
                SizedBox(width: 8.w),
                _buildHeroBadge('متابع معتمد', AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthReadingsSection(BuildContext context, List<dynamic> readings) {
    return FadeInUp(
      delay: const Duration(milliseconds: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39C12).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.show_chart_rounded,
                    color: const Color(0xFFF39C12),
                    size: 16.r,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'القراءات الصحية والمؤشرات الحية',
                  style: GoogleFonts.cairo(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39C12).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${readings.length} قراءات',
                    style: GoogleFonts.cairo(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF39C12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          if (readings.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1D26).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.monitor_heart_rounded,
                    size: 32.r,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'لا توجد قراءات صحية مسجلة لهذا المريض',
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 130.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: readings.length,
                separatorBuilder: (context, index) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final reading = readings[index] as Map<String, dynamic>;
                  return _buildReadingHorizontalCard(reading);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadingHorizontalCard(Map<String, dynamic> reading) {
    final type = reading['type'] as String? ?? 'قراءة';
    final value = reading['value'];
    final createdAtStr = reading['createdAt'] as String? ?? '';

    final createdAt = DateTime.tryParse(createdAtStr);
    final dateFormatted = createdAt != null
        ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
        : 'تاريخ غير معروف';

    final arabicType = _getArabicType(type);
    final unit = _getUnit(type);
    final color = _getReadingColor(type);

    return Container(
      width: 155.w,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D26).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getReadingIcon(type),
                  color: color,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  arabicType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          if (value != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    '$value',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (unit.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(right: 3.w),
                    child: Text(
                      unit.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            )
          else
            Text(
              'بدون قيمة',
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 9.r, color: AppColors.textSecondary),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  dateFormatted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getReadingColor(String type) {
    switch (type.toLowerCase()) {
      case 'bloodpressure':
        return const Color(0xFFFF4757);
      case 'bloodsugar':
      case 'glucose':
        return const Color(0xFFFF9F43);
      case 'weight':
        return const Color(0xFF00B894);
      case 'heartrate':
        return const Color(0xFF9B59B6);
      case 'temperature':
        return const Color(0xFF00C48C);
      default:
        return AppColors.primary;
    }
  }

  IconData _getReadingIcon(String type) {
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

  Widget _buildHeroBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: iconColor, size: 20.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 10.5.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.cairo(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13.r,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTerminate(BuildContext context) {
    final blocContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: Text(
            'إنهاء العلاقة العلاجية',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18.sp, color: AppColors.textPrimary),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في إنهاء العلاقة العلاجية مع هذا المريض؟ لا يمكن التراجع عن هذا الإجراء.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13.sp, color: AppColors.textSecondary),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                blocContext.read<PatientBloc>().add(
                  PatientTerminateSubmitted(patientId),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(
                'تأكيد الإنهاء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

