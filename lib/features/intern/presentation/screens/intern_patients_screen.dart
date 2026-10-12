import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/widgets/app_avatar.dart';
import '../bloc/intern_patients_bloc.dart';
import '../bloc/intern_patients_event.dart';
import '../bloc/intern_patients_state.dart';
import '../../domain/entities/intern_patient_entity.dart';
import 'intern_patient_detail_screen.dart';

/// Intern's patient list — a patient appears here automatically once a
/// chat conversation exists or a draft was submitted for them (backend
/// Module K: GET /intern/my-patients). No tabs/search/accept-reject here,
/// unlike the Pharmacist's roster screen — the Intern never manages
/// assignments directly.
class InternPatientsScreen extends StatelessWidget {
  const InternPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<InternPatientsBloc>()..add(InternPatientsRequested()),
      child: const _InternPatientsView(),
    );
  }
}

class _InternPatientsView extends StatelessWidget {
  const _InternPatientsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildAmbientMeshBackground(),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 12.h),
                _buildHeader(context),
                SizedBox(height: 16.h),
                Expanded(
                  child: BlocBuilder<InternPatientsBloc, InternPatientsState>(
                    builder: (context, state) {
                      if (state is InternPatientsLoading || state is InternPatientsInitial) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
                        );
                      }
                      if (state is InternPatientsError) {
                        return _ErrorView(
                          message: state.message,
                          onRetry: () =>
                              context.read<InternPatientsBloc>().add(InternPatientsRequested()),
                        );
                      }
                      if (state is InternPatientsNoAssignment) {
                        return const _EmptyView(
                          message: 'لسه ما اترتبطش بمشرف من كليتك. تواصل مع الكلية.',
                          icon: Icons.school_outlined,
                        );
                      }
                      if (state is InternPatientsLoaded) {
                        if (state.items.isEmpty) {
                          return const _EmptyView(
                            message: 'لسه مالكش مرضى — استنى مريض يبعتلك رسالة أو ابعت draft على وصفة.',
                          );
                        }
                        return RefreshIndicator(
                          color: AppColors.primaryGreen,
                          onRefresh: () async {
                            context.read<InternPatientsBloc>().add(InternPatientsRequested());
                            await context.read<InternPatientsBloc>().stream.firstWhere(
                                  (s) => s is InternPatientsLoaded || s is InternPatientsError,
                                );
                          },
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            itemCount: state.items.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              return FadeInUp(
                                delay: Duration(milliseconds: 60 * index),
                                duration: const Duration(milliseconds: 350),
                                child: _PatientCard(patient: state.items[index]),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
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

  Widget _buildAmbientMeshBackground() {
    return Stack(
      children: [
        Positioned(
          top: -60.h,
          right: -60.w,
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

  Widget _buildHeader(BuildContext context) {
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
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18.r, color: AppColors.textPrimary),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'مرضاي',
            style: GoogleFonts.cairo(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

Color _riskColor(String riskLevel) {
  switch (riskLevel) {
    case 'Critical':
      return AppColors.error;
    case 'High':
      return Colors.deepOrange;
    case 'Medium':
      return Colors.orange;
    default:
      return AppColors.primaryGreen;
  }
}

String _riskLabel(String riskLevel) {
  switch (riskLevel) {
    case 'Critical':
      return 'حرج';
    case 'High':
      return 'مرتفع';
    case 'Medium':
      return 'متوسط';
    default:
      return 'منخفض';
  }
}

class _PatientCard extends StatelessWidget {
  final InternPatientEntity patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(patient.riskLevel);
    final totalDrafts = patient.prescriptionDraftCount + patient.medicationPlanDraftCount;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InternPatientDetailScreen(patientUserId: patient.patientUserId),
        ),
      ),
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
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: riskColor, width: 1.6),
                  ),
                  child: AppAvatar(avatarUrl: null, name: patient.name, radius: 24.r),
                ),
                if (patient.hasConversation)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 11.r,
                      height: 11.r,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          _riskLabel(patient.riskLevel),
                          style: GoogleFonts.cairo(fontSize: 10.sp, fontWeight: FontWeight.w800, color: riskColor),
                        ),
                      ),
                      if (totalDrafts > 0) ...[
                        SizedBox(width: 8.w),
                        Text(
                          '$totalDrafts مسودة',
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13.r, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyView({required this.message, this.icon = Icons.people_outline_rounded});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48.r, color: AppColors.primary),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14.5.sp, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              child: Icon(Icons.error_outline_rounded, size: 48.r, color: AppColors.error),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13.5.sp, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
