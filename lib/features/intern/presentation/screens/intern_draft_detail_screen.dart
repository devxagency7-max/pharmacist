import 'package:flutter/material.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import '../../domain/entities/intern_draft_entity.dart';
import '../../domain/repositories/intern_repository.dart';

/// Read-only detail view for a single draft the intern submitted. Interns
/// can't edit or withdraw a submitted draft — this just shows what was sent
/// and, once reviewed, the supervisor's feedback.
class InternDraftDetailScreen extends StatefulWidget {
  final String draftId;

  const InternDraftDetailScreen({super.key, required this.draftId});

  @override
  State<InternDraftDetailScreen> createState() => _InternDraftDetailScreenState();
}

class _InternDraftDetailScreenState extends State<InternDraftDetailScreen> {
  InternDraftEntity? _draft;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final draft = await getIt<InternRepository>().getDraftDetail(widget.draftId);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mapErrorToMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'تفاصيل المسودة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(_error!)
                : _buildDetail(_draft!),
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
              onPressed: _load,
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(InternDraftEntity draft) {
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPrescription ? Icons.receipt_long_rounded : Icons.medication_outlined,
                color: AppColors.primaryGreen,
                size: 26.r,
              ),
              SizedBox(width: 10.w),
              Text(
                isPrescription ? 'مراجعة روشتة' : 'خطة دواء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16.sp),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 12.sp, color: statusColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          if (draft.internClinicalNotes != null && draft.internClinicalNotes!.isNotEmpty) ...[
            _buildSection('ملاحظاتك', draft.internClinicalNotes!),
            SizedBox(height: 16.h),
          ],
          if (draft.supervisorFeedback != null && draft.supervisorFeedback!.isNotEmpty) ...[
            _buildSection('ملاحظات المشرف', draft.supervisorFeedback!),
            SizedBox(height: 16.h),
          ],
          _buildSection(
            'تاريخ الإرسال',
            '${draft.createdAt.year}-${draft.createdAt.month.toString().padLeft(2, '0')}-${draft.createdAt.day.toString().padLeft(2, '0')}',
          ),
          if (draft.reviewedAt != null) ...[
            SizedBox(height: 16.h),
            _buildSection(
              'تاريخ المراجعة',
              '${draft.reviewedAt!.year}-${draft.reviewedAt!.month.toString().padLeft(2, '0')}-${draft.reviewedAt!.day.toString().padLeft(2, '0')}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 12.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.white, width: 1.2),
          ),
          child: Text(
            content,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13.sp, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
