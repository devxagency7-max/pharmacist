import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/entities/reminder_schedule_entity.dart';
import '../../domain/repositories/reminder_repository.dart';

const _typeOptions = ['Medication', 'Lab', 'DoctorVisit', 'Scan', 'Other'];
const _typeLabels = {
  'Medication': 'دواء',
  'Lab': 'تحليل',
  'DoctorVisit': 'زيارة طبيب',
  'Scan': 'أشعة',
  'Other': 'أخرى',
};
const _frequencyOptions = ['Once', 'Daily', 'EveryXHours'];
const _frequencyLabels = {'Once': 'مرة واحدة', 'Daily': 'يومياً', 'EveryXHours': 'كل عدد ساعات'};

/// Create or edit a patient reminder (backend Module J). Pops with the
/// created/updated [ReminderScheduleEntity] on success.
class ReminderFormScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final ReminderScheduleEntity? existingReminder;

  const ReminderFormScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.existingReminder,
  });

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _intervalHoursController;

  String _type = _typeOptions.first;
  String _frequencyType = _frequencyOptions.first;
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.existingReminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingReminder;
    _titleController = TextEditingController(text: r?.title ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _intervalHoursController = TextEditingController(text: r?.intervalHours?.toString() ?? '');
    if (r != null) {
      _type = r.type;
      _frequencyType = r.frequencyType;
      _startTime = r.startTime;
      _endTime = r.endTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _intervalHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startTime : (_endTime ?? _startTime);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = combined;
      } else {
        _endTime = combined;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final repository = getIt<ReminderRepository>();
    final intervalHours = _intervalHoursController.text.trim().isEmpty
        ? null
        : int.tryParse(_intervalHoursController.text.trim());

    try {
      final ReminderScheduleEntity result;
      if (_isEdit) {
        result = await repository.update(
          widget.existingReminder!.id,
          type: _type,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          frequencyType: _frequencyType,
          intervalHours: intervalHours,
          startTime: _startTime,
          endTime: _endTime,
        );
      } else {
        result = await repository.create(
          patientId: widget.patientId,
          type: _type,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          frequencyType: _frequencyType,
          intervalHours: intervalHours,
          startTime: _startTime,
          endTime: _endTime,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = asApiException(e)?.statusCode == 404
            ? 'لا توجد علاقة علاجية نشطة مع هذا المريض، لا يمكنك إدارة تذكيراته.'
            : mapErrorToMessage(e);
      });
    }
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _isEdit ? 'تعديل تذكير' : 'إضافة تذكير',
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
            _dropdown('النوع', _type, _typeOptions, _typeLabels, (v) => setState(() => _type = v!)),
            SizedBox(height: 12.h),
            _textField(_titleController, 'العنوان', required: true),
            SizedBox(height: 12.h),
            _textField(_descriptionController, 'وصف (اختياري)', maxLines: 3),
            SizedBox(height: 12.h),
            _dropdown(
              'التكرار',
              _frequencyType,
              _frequencyOptions,
              _frequencyLabels,
              (v) => setState(() => _frequencyType = v!),
            ),
            if (_frequencyType == 'EveryXHours') ...[
              SizedBox(height: 12.h),
              _textField(
                _intervalHoursController,
                'كل كام ساعة',
                required: true,
                keyboardType: TextInputType.number,
              ),
            ],
            SizedBox(height: 12.h),
            _dateTimeField('وقت البداية', _startTime, () => _pickDateTime(isStart: true)),
            SizedBox(height: 12.h),
            _dateTimeField(
              'وقت النهاية (اختياري)',
              _endTime,
              () => _pickDateTime(isStart: false),
              onClear: _endTime != null ? () => setState(() => _endTime = null) : null,
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
                        _isEdit ? 'حفظ التعديلات' : 'إضافة التذكير',
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

  Widget _dateTimeField(String label, DateTime? value, VoidCallback onTap, {VoidCallback? onClear}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
          suffixIcon: onClear != null ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear) : null,
        ),
        child: Text(value != null ? _formatDateTime(value) : 'اختر التاريخ والوقت', style: GoogleFonts.cairo()),
      ),
    );
  }
}
