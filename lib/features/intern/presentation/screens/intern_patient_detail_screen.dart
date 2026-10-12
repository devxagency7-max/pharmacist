import 'dart:ui';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
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
import '../bloc/intern_patients_bloc.dart';
import '../bloc/intern_patients_event.dart';
import '../bloc/intern_patients_state.dart';
import '../../domain/entities/intern_patient_entity.dart';
import 'draft_prescription_review_screen.dart';
import 'draft_medication_plan_screen.dart';

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

Color _draftStatusColor(String status) {
  switch (status) {
    case 'Approved':
      return AppColors.primaryGreen;
    case 'Rejected':
      return AppColors.error;
    default:
      return Colors.orange;
  }
}

String _draftStatusLabel(String status) {
  switch (status) {
    case 'Approved':
      return 'مقبولة';
    case 'Rejected':
      return 'مرفوضة';
    default:
      return 'قيد المراجعة';
  }
}

/// Patient detail for the Intern — Chat / Prescriptions / Medication Plans.
/// No standalone "Profile" tab: identity/risk info lives in the header
/// card, matching how the Pharmacist's PatientDetailScreen does it too.
class InternPatientDetailScreen extends StatelessWidget {
  final String patientUserId;

  const InternPatientDetailScreen({super.key, required this.patientUserId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<InternPatientsBloc>()..add(InternPatientDetailRequested(patientUserId)),
      child: const _InternPatientDetailView(),
    );
  }
}

class _InternPatientDetailView extends StatefulWidget {
  const _InternPatientDetailView();

  @override
  State<_InternPatientDetailView> createState() => _InternPatientDetailViewState();
}

class _InternPatientDetailViewState extends State<_InternPatientDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openChat(BuildContext context, InternPatientEntity patient) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
    );
    try {
      final conv = await getIt<ChatRepository>()
          .startConversation(otherParticipantId: patient.patientUserId);
      await getIt<ChatSignalRService>().joinConversation(conv.id);
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversationId: conv.id,
            otherParticipantName: patient.name,
            patientId: patient.patientUserId,
            conversationStatus: conv.status,
          ),
        ),
      );
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(mapErrorToMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildAmbientMeshBackground(),
          SafeArea(
            child: BlocBuilder<InternPatientsBloc, InternPatientsState>(
              builder: (context, state) {
                if (state is InternPatientDetailLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
                  );
                }
                if (state is InternPatientDetailError) {
                  return _buildError(context, state.message);
                }
                if (state is InternPatientDetailLoaded) {
                  return Column(
                    children: [
                      SizedBox(height: 12.h),
                      _buildHeader(context, state.patient),
                      SizedBox(height: 16.h),
                      _buildTabBar(),
                      SizedBox(height: 12.h),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _ChatTab(
                              patient: state.patient,
                              onOpenChat: () => _openChat(context, state.patient),
                            ),
                            _PrescriptionsTab(prescriptions: state.prescriptions),
                            _MedicationPlansTab(medicationPlans: state.medicationPlans),
                          ],
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

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48.r, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13.5.sp),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('رجوع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InternPatientEntity patient) {
    final riskColor = _riskColor(patient.riskLevel);
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: riskColor, width: 1.6),
            ),
            child: AppAvatar(avatarUrl: null, name: patient.name, radius: 22.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: GoogleFonts.cairo(fontSize: 15.sp, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'خطورة ${_riskLabel(patient.riskLevel)}',
                    style: GoogleFonts.cairo(fontSize: 10.sp, fontWeight: FontWeight.w800, color: riskColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12.r),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.w700),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'المحادثة'),
            Tab(text: 'الروشتات'),
            Tab(text: 'خطط الدواء'),
          ],
        ),
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  final InternPatientEntity patient;
  final VoidCallback onOpenChat;

  const _ChatTab({required this.patient, required this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48.r, color: AppColors.primaryGreen),
            SizedBox(height: 16.h),
            Text(
              patient.hasConversation ? 'عندك محادثة مفتوحة مع المريض ده' : 'ابدأ محادثة مع المريض',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onOpenChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Text(
                'فتح المحادثة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionsTab extends StatelessWidget {
  final List<InternPatientPrescriptionEntity> prescriptions;

  const _PrescriptionsTab({required this.prescriptions});

  @override
  Widget build(BuildContext context) {
    if (prescriptions.isEmpty) {
      return Center(
        child: Text(
          'لا توجد روشتات لهذا المريض بعد.',
          style: GoogleFonts.cairo(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: prescriptions.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final p = prescriptions[index];
        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.white, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.doctorName ?? 'روشتة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 13.sp),
                    ),
                  ),
                  if (p.myDraftStatus != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: _draftStatusColor(p.myDraftStatus!).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _draftStatusLabel(p.myDraftStatus!),
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: _draftStatusColor(p.myDraftStatus!),
                        ),
                      ),
                    ),
                ],
              ),
              if (p.clinicName != null) ...[
                SizedBox(height: 4.h),
                Text(
                  p.clinicName!,
                  style: GoogleFonts.cairo(fontSize: 11.5.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DraftPrescriptionReviewScreen(
                        initialPrescriptionId: p.prescriptionId,
                      ),
                    ),
                  ),
                  child: Text('اقترح تعديل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.sp)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MedicationPlansTab extends StatelessWidget {
  final List<InternPatientMedicationPlanEntity> medicationPlans;

  const _MedicationPlansTab({required this.medicationPlans});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DraftMedicationPlanScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text('خطة جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.sp)),
          ),
        ),
        SizedBox(height: 12.h),
        if (medicationPlans.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Center(
              child: Text(
                'لا توجد خطط دواء لهذا المريض بعد.',
                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          )
        else
          ...medicationPlans.map((plan) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.medicineName,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 13.sp),
                            ),
                          ),
                          if (plan.myDraftStatus != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: _draftStatusColor(plan.myDraftStatus!).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                _draftStatusLabel(plan.myDraftStatus!),
                                style: GoogleFonts.cairo(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _draftStatusColor(plan.myDraftStatus!),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (plan.dosage != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          plan.dosage!,
                          style: GoogleFonts.cairo(fontSize: 11.5.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DraftMedicationPlanScreen(
                                initialExistingMedicationPlanId: plan.medicationPlanId,
                              ),
                            ),
                          ),
                          child: Text('اقترح تعديل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.sp)),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
