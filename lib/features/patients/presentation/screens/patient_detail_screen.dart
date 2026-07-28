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

/// GET /pharmacists/patients/{id} + PUT .../terminate (backend Module D).
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'ملف المريض',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          BlocBuilder<PatientBloc, PatientState>(
            builder: (context, state) {
              if (state is! PatientDetailLoaded) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  Icons.person_remove_alt_1_rounded,
                  color: AppColors.error,
                ),
                tooltip: 'إنهاء العلاقة العلاجية',
                onPressed: () => _confirmTerminate(context),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<PatientBloc, PatientState>(
        listener: (context, state) {
          if (state is PatientTerminateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إنهاء العلاقة العلاجية.')),
            );
            Navigator.pop(context);
          } else if (state is PatientTerminateError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is PatientDetailLoading || state is PatientInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PatientDetailError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  state.message,
                  style: GoogleFonts.cairo(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (state is PatientDetailLoaded) {
            final p = state.patient;
            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                AppAvatar(avatarUrl: p.avatarUrl, name: p.name, radius: 40.r),
                SizedBox(height: 12.h),
                Center(
                  child: Text(
                    p.name,
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    p.email,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (p.phone != null && p.phone!.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        p.phone!,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 24.h),

                // Chat card with action
                _buildSectionCard(
                  'محادثة الاستشارات (شاملة الـ AI)',
                  Icon(
                    Icons.chat_bubble_rounded,
                    color: AppColors.primaryGreen,
                    size: 20.r,
                  ),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    // The backend now returns this patient's real
                    // conversationId directly on GET /pharmacists/patients/{id}
                    // (distinct from, and never confused with, their separate
                    // AI-conversation id). Use it directly when present —
                    // startConversation is only needed the first time, before
                    // any conversation exists with this patient.
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
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    );
                    try {
                      final conv = await getIt<ChatRepository>()
                          .startConversation(otherParticipantId: p.patientId);
                      // Join this conversation's SignalR group right away on
                      // the app-wide connection, so ConversationListBloc
                      // picks up live activity on it even if the pharmacist
                      // never reopens this exact chat screen this session —
                      // MainScreen's startup join-all only covers
                      // conversations that already existed at app launch.
                      await getIt<ChatSignalRService>().joinConversation(
                        conv.id,
                      );
                      navigator.pop(); // Dismiss loading
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
                      navigator.pop(); // Dismiss loading
                      messenger.showSnackBar(
                        SnackBar(content: Text('تعذر فتح المحادثة: $e')),
                      );
                    }
                  },
                ),
                SizedBox(height: 12.h),

                _buildSectionCard(
                  'السجلات الطبية للأرشيف',
                  p.medicalRecords.length,
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
                SizedBox(height: 12.h),
                _buildSectionCard(
                  'القراءات الصحية والمؤشرات الحية',
                  p.healthReadings.length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HealthReadingsScreen(
                        readings: p.healthReadings,
                        patientName: p.name,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                _buildSectionCard(
                  'خطط الأدوية المعتمدة',
                  p.medicationPlans.length,
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
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionCard(String title, dynamic value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                if (value is int)
                  Text(
                    '$value',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  )
                else if (value is Widget)
                  value,
                if (onTap != null) ...[
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14.r,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ],
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
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'إنهاء العلاقة العلاجية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'هل أنت متأكد؟ لا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              blocContext.read<PatientBloc>().add(
                PatientTerminateSubmitted(patientId),
              );
            },
            child: Text(
              'إنهاء',
              style: GoogleFonts.cairo(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
