import 'package:flutter/material.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/errors/api_exception.dart';
import '../../domain/repositories/intern_repository.dart';

/// Mirrors [DraftPrescriptionReviewScreen]. Leaving the plan id blank
/// submits a brand-new plan proposal instead of a revision, per the backend
/// contract. [initialExistingMedicationPlanId] pre-fills and locks the id
/// field when opened from a specific patient's existing plan row.
class DraftMedicationPlanScreen extends StatefulWidget {
  final String? initialExistingMedicationPlanId;

  const DraftMedicationPlanScreen({super.key, this.initialExistingMedicationPlanId});

  @override
  State<DraftMedicationPlanScreen> createState() => _DraftMedicationPlanScreenState();
}

class _DraftMedicationPlanScreenState extends State<DraftMedicationPlanScreen> {
  final _planIdController = TextEditingController();
  final _payloadController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialExistingMedicationPlanId != null) {
      _planIdController.text = widget.initialExistingMedicationPlanId!;
    }
  }

  @override
  void dispose() {
    _planIdController.dispose();
    _payloadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final payloadJson = _payloadController.text.trim();
    if (payloadJson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'محتوى خطة الدواء مطلوب',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final planId = _planIdController.text.trim();
      final draft = await getIt<InternRepository>().draftMedicationPlan(
        existingMedicationPlanId: planId.isEmpty ? null : planId,
        payloadJson: payloadJson,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال المسودة لمشرفك (${draft.status})',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final apiError = asApiException(e);
      if (apiError != null && apiError.errorCode == 'INTERN_PATIENT_CAP_REACHED') {
        _showPatientCapDialog(apiError);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mapErrorToMessage(e),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showPatientCapDialog(ApiException e) {
    final current = e.extra?['details']?['currentPatientCount'] ?? '?';
    final max = e.extra?['details']?['maxPatientsPerIntern'] ?? '?';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('وصلت للحد الأقصى', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Text(
          'عندك $current مريض من أصل $max مسموح بيهم. كلّم المعيد أو الأدمن يرفع الحد، أو انهِ متابعة مريض قديم — أو ابعت المسودة على مريض عندك بالفعل.',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('حسنًا', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'مسودة خطة دواء',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('رقم خطة الدواء الحالية (اتركه فارغًا لخطة جديدة)'),
              TextField(
                controller: _planIdController,
                enabled: widget.initialExistingMedicationPlanId == null,
              ),
              SizedBox(height: 16.h),
              _buildLabel('محتوى الخطة المقترحة'),
              TextField(
                controller: _payloadController,
                maxLines: 6,
                decoration: const InputDecoration(hintText: 'اكتب تفاصيل خطة الدواء هنا'),
              ),
              SizedBox(height: 16.h),
              _buildLabel('ملاحظات (اختياري)'),
              TextField(controller: _notesController, maxLines: 2),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'إرسال إلى المشرف',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13.sp, color: AppColors.textSecondary),
      ),
    );
  }
}
