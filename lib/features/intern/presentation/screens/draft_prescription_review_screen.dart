import 'package:flutter/material.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/errors/api_exception.dart';
import '../../domain/repositories/intern_repository.dart';

/// Takes an optional [initialPrescriptionId] — pre-filled and locked when
/// opened from a specific patient's prescription row (the id is already
/// known there); left editable for manual entry when opened directly with
/// no patient context.
class DraftPrescriptionReviewScreen extends StatefulWidget {
  final String? initialPrescriptionId;

  const DraftPrescriptionReviewScreen({super.key, this.initialPrescriptionId});

  @override
  State<DraftPrescriptionReviewScreen> createState() =>
      _DraftPrescriptionReviewScreenState();
}

class _DraftPrescriptionReviewScreenState extends State<DraftPrescriptionReviewScreen> {
  final _prescriptionIdController = TextEditingController();
  final _payloadController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrescriptionId != null) {
      _prescriptionIdController.text = widget.initialPrescriptionId!;
    }
  }

  @override
  void dispose() {
    _prescriptionIdController.dispose();
    _payloadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prescriptionId = _prescriptionIdController.text.trim();
    final payloadJson = _payloadController.text.trim();
    if (prescriptionId.isEmpty || payloadJson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'رقم الروشتة ومحتوى المراجعة مطلوبين',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final draft = await getIt<InternRepository>().draftPrescriptionRecommendation(
        prescriptionId,
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
          'مسودة مراجعة روشتة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('رقم الروشتة (Prescription ID)'),
              TextField(
                controller: _prescriptionIdController,
                enabled: widget.initialPrescriptionId == null,
              ),
              SizedBox(height: 16.h),
              _buildLabel('محتوى المراجعة المقترحة'),
              TextField(
                controller: _payloadController,
                maxLines: 6,
                decoration: const InputDecoration(hintText: 'اكتب تفاصيل مراجعتك للروشتة هنا'),
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
