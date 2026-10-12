import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import '../bloc/intern_home_bloc.dart';
import '../bloc/intern_home_event.dart';
import '../bloc/intern_home_state.dart';
import '../../domain/entities/intern_supervisor_entity.dart';
import '../../domain/entities/intern_program_entity.dart';
import '../../domain/entities/intern_draft_entity.dart';
import 'draft_prescription_review_screen.dart';
import 'draft_medication_plan_screen.dart';
import 'intern_draft_detail_screen.dart';
import 'intern_patients_screen.dart';

/// Intern's home dashboard — supervisor card, training program card,
/// progress KPIs, and a list of submitted drafts. Entry point for the two
/// draft-submission screens, since the intern has no roster/queue of their
/// own to browse (see backend's INTERN_API_GUIDE.md §5).
class InternHomeScreen extends StatelessWidget {
  const InternHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<InternHomeBloc>()..add(InternHomeRequested()),
      child: const _InternHomeView(),
    );
  }
}

class _InternHomeView extends StatefulWidget {
  const _InternHomeView();

  @override
  State<_InternHomeView> createState() => _InternHomeViewState();
}

class _InternHomeViewState extends State<_InternHomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            _buildHeader(context),
            Expanded(
              child: BlocBuilder<InternHomeBloc, InternHomeState>(
                builder: (context, state) {
                  if (state is InternHomeLoading || state is InternHomeInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is InternHomeError) {
                    return _buildErrorState(context, state.message);
                  }
                  final loaded = state as InternHomeLoaded;
                  if (loaded.progress == null) {
                    return _buildNoAssignmentState();
                  }
                  return _buildDashboard(context, loaded);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
            'تقدمي كمتدرب',
            style: GoogleFonts.cairo(
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAssignmentState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64.r, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text(
              'لسه ما اترتبطش بمشرف من كليتك. تواصل مع الكلية.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56.r, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.read<InternHomeBloc>().add(InternHomeRequested()),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, InternHomeLoaded state) {
    final progress = state.progress!;
    final hoursRatio = progress.requiredHours <= 0
        ? 0.0
        : (progress.loggedHours / progress.requiredHours).clamp(0.0, 1.0);
    final totalDraftsSubmitted =
        progress.prescriptionReviewDraftsSubmitted + progress.medicationPlanDraftsSubmitted;

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () async {
        context.read<InternHomeBloc>().add(InternHomeRequested());
        await context.read<InternHomeBloc>().stream.firstWhere(
              (s) => s is InternHomeLoaded || s is InternHomeError,
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.supervisor != null) ...[
              _buildSupervisorCard(state.supervisor!),
              SizedBox(height: 16.h),
            ],
            if (state.program != null) ...[
              _buildProgramCard(state.program!),
              SizedBox(height: 16.h),
            ],
            _buildStatCard(
              title: 'ساعات التدريب',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${progress.loggedHours.toStringAsFixed(1)} / ${progress.requiredHours.toStringAsFixed(1)} ساعة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15.sp),
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: LinearProgressIndicator(
                      value: hoursRatio,
                      minHeight: 10.h,
                      backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'منها ${progress.verifiedHours.toStringAsFixed(1)} ساعة موثّقة',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'مسودات مُرسلة',
                    child: Text(
                      '$totalDraftsSubmitted',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 22.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatCard(
                    title: 'مقبولة',
                    child: Text(
                      '${progress.draftsApproved}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 22.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatCard(
                    title: 'قيد المراجعة',
                    child: Text(
                      '${progress.draftsPendingReview}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 22.sp),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InternPatientsScreen()),
                ),
                icon: const Icon(Icons.people_alt_rounded),
                label: Text('مرضاي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isLoggingHours ? null : () => _showLogHoursDialog(context),
                icon: state.isLoggingHours
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_task_rounded),
                label: Text(
                  'تسجيل ساعات تدريب',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DraftPrescriptionReviewScreen()),
                ),
                child: Text(
                  'إرسال مسودة مراجعة روشتة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DraftMedicationPlanScreen()),
                ),
                child: Text(
                  'إرسال مسودة خطة دواء',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'مسوداتي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16.sp, color: AppColors.textPrimary),
            ),
            SizedBox(height: 12.h),
            if (state.drafts.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  'لسه مبعتش أي مسودة.',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              )
            else
              ...state.drafts.map((draft) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _buildDraftRow(context, draft),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildSupervisorCard(InternSupervisorEntity supervisor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_services_outlined, color: AppColors.primaryGreen, size: 28.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحت إشراف د. ${supervisor.supervisorName}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14.sp),
                ),
                if (supervisor.pharmacyName != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    [supervisor.pharmacyName, supervisor.branchName]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' - '),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(InternProgramEntity program) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_outlined, color: AppColors.primaryGreen, size: 28.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.programName,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14.sp),
                ),
                if (program.facultyName != null || program.universityName != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    [program.facultyName, program.universityName]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' - '),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }

  Widget _buildDraftRow(BuildContext context, InternDraftEntity draft) {
    final isPrescription = draft.entityKind == 'PrescriptionReview';
    final statusColor = switch (draft.status) {
      'Accepted' => AppColors.primaryGreen,
      'Rejected' => AppColors.error,
      _ => Colors.orange,
    };
    final statusLabel = switch (draft.status) {
      'Accepted' => 'مقبولة',
      'Rejected' => 'مرفوضة',
      _ => 'قيد المراجعة',
    };

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InternDraftDetailScreen(draftId: draft.draftId)),
      ),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(
              isPrescription ? Icons.receipt_long_rounded : Icons.medication_outlined,
              color: AppColors.primaryGreen,
              size: 22.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPrescription ? 'مراجعة روشتة' : 'خطة دواء',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 13.sp),
                  ),
                  if (draft.internClinicalNotes != null && draft.internClinicalNotes!.isNotEmpty)
                    Text(
                      draft.internClinicalNotes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 10.sp, color: statusColor),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary, size: 18.r),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogHoursDialog(BuildContext context) async {
    final bloc = context.read<InternHomeBloc>();
    final hoursController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('تسجيل ساعات تدريب', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'التاريخ'),
                  child: Text(
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'عدد الساعات'),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'وصف النشاط'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    final hours = double.tryParse(hoursController.text.trim());
    final description = descriptionController.text.trim();
    if (hours == null || hours <= 0 || description.isEmpty) return;

    bloc.add(
      InternTrainingHoursLogSubmitted(
        date: selectedDate,
        hours: hours,
        activityDescription: description,
      ),
    );
  }
}
