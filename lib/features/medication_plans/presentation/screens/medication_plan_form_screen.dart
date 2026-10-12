import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/repositories/medication_plan_repository.dart';

const _timeOfDayOptions = ['Morning', 'Afternoon', 'Evening', 'Night'];
const _timeOfDayLabels = {
  'Morning': 'الصباح',
  'Afternoon': 'الظهيرة',
  'Evening': 'المساء',
  'Night': 'الليل',
};
const _frequencyOptions = ['Daily', 'Weekly'];
const _frequencyLabels = {'Daily': 'يومياً', 'Weekly': 'أسبوعياً'};

/// POST /medications (create) or PUT /medications/{id} (edit) — pharmacist-authored
/// medication plan for an Active-assigned patient. Pops with `true` on success so
/// the caller can refresh the patient detail screen.
class MedicationPlanFormScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  /// When editing an existing plan, pass its raw JSON (as embedded in
  /// PatientDetailEntity.medicationPlans). Null means "create new".
  final Map<String, dynamic>? existingPlan;

  const MedicationPlanFormScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.existingPlan,
  });

  @override
  State<MedicationPlanFormScreen> createState() => _MedicationPlanFormScreenState();
}

class _MedicationPlanFormScreenState extends State<MedicationPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _medicineNameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _quantityController;
  late final TextEditingController _doctorController;
  late final TextEditingController _durationController;

  String _timeOfDay = _timeOfDayOptions.first;
  String _frequency = _frequencyOptions.first;
  DateTime _startDate = DateTime.now();
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.existingPlan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.existingPlan;
    _medicineNameController = TextEditingController(text: plan?['medicineName'] as String? ?? '');
    _dosageController = TextEditingController(text: plan?['dosage'] as String? ?? '');
    _instructionsController = TextEditingController(text: plan?['instructions'] as String? ?? '');
    _quantityController = TextEditingController(text: plan?['quantity']?.toString() ?? '');
    _doctorController = TextEditingController(text: plan?['prescribingDoctor'] as String? ?? '');
    _durationController = TextEditingController(text: plan?['durationDays']?.toString() ?? '');

    final planTimeOfDay = plan?['timeOfDay'] as String?;
    if (planTimeOfDay != null && _timeOfDayOptions.contains(planTimeOfDay)) {
      _timeOfDay = planTimeOfDay;
    }
    final planFrequency = plan?['frequency'] as String?;
    if (planFrequency != null && _frequencyOptions.contains(planFrequency)) {
      _frequency = planFrequency;
    }
    final planStartDate = plan?['startDate'] as String?;
    if (planStartDate != null) {
      _startDate = DateTime.tryParse(planStartDate) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _quantityController.dispose();
    _doctorController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final repository = getIt<MedicationPlanRepository>();
    final quantity = _quantityController.text.trim().isEmpty
        ? null
        : int.tryParse(_quantityController.text.trim());
    final durationDays = int.parse(_durationController.text.trim());

    try {
      if (_isEdit) {
        await repository.update(
          widget.existingPlan!['id'] as String,
          medicineName: _medicineNameController.text.trim(),
          dosage: _dosageController.text.trim(),
          instructions: _instructionsController.text.trim(),
          quantity: quantity,
          prescribingDoctor: _doctorController.text.trim(),
          timeOfDay: _timeOfDay,
          frequency: _frequency,
          startDate: _startDate,
          durationDays: durationDays,
        );
      } else {
        await repository.create(
          patientId: widget.patientId,
          medicineName: _medicineNameController.text.trim(),
          dosage: _dosageController.text.trim(),
          instructions: _instructionsController.text.trim(),
          quantity: quantity,
          prescribingDoctor: _doctorController.text.trim(),
          timeOfDay: _timeOfDay,
          frequency: _frequency,
          startDate: _startDate,
          durationDays: durationDays,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = asApiException(e)?.statusCode == 404
            ? 'لا توجد علاقة علاجية نشطة مع هذا المريض، لا يمكنك تعديل خطته الدوائية.'
            : mapErrorToMessage(e);
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
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _isEdit ? 'تعديل خطة دوائية' : 'إضافة خطة دوائية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Text('لـ: ${widget.patientName}', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
            SizedBox(height: 16.h),
            if (_errorMessage != null) ...[
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(_errorMessage!, style: GoogleFonts.cairo(color: AppColors.error)),
              ),
              SizedBox(height: 16.h),
            ],
            _textField(_medicineNameController, 'اسم الدواء', required: true),
            SizedBox(height: 12.h),
            _textField(_dosageController, 'الجرعة', required: true),
            SizedBox(height: 12.h),
            _textField(_instructionsController, 'تعليمات (اختياري)', maxLines: 3),
            SizedBox(height: 12.h),
            _textField(_quantityController, 'الكمية (اختياري)', keyboardType: TextInputType.number),
            SizedBox(height: 12.h),
            _textField(_doctorController, 'اسم الطبيب المعالج (اختياري)'),
            SizedBox(height: 12.h),
            _dropdown('وقت الجرعة', _timeOfDay, _timeOfDayOptions, _timeOfDayLabels, (v) => setState(() => _timeOfDay = v!)),
            SizedBox(height: 12.h),
            _dropdown('التكرار', _frequency, _frequencyOptions, _frequencyLabels, (v) => setState(() => _frequency = v!)),
            SizedBox(height: 12.h),
            _dateField(),
            SizedBox(height: 12.h),
            _textField(
              _durationController,
              'مدة العلاج (بالأيام)',
              required: true,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEdit ? 'حفظ التعديلات' : 'إنشاء الخطة',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      ),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    Map<String, String> labels,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      style: GoogleFonts.cairo(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      ),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(labels[o] ?? o, style: GoogleFonts.cairo())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: _pickStartDate,
      borderRadius: BorderRadius.circular(12.r),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ البداية',
          labelStyle: GoogleFonts.cairo(),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
        ),
        child: Text(
          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
          style: GoogleFonts.cairo(),
        ),
      ),
    );
  }
}
