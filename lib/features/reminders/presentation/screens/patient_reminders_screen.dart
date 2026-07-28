import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/errors/api_exception.dart';
import '../../domain/entities/reminder_schedule_entity.dart';
import '../../domain/repositories/reminder_repository.dart';
import 'reminder_form_screen.dart';

const _typeLabels = {
  'Medication': 'دواء',
  'Lab': 'تحليل',
  'DoctorVisit': 'زيارة طبيب',
  'Scan': 'أشعة',
  'Other': 'أخرى',
};

/// Manage reminders for one Active-assigned patient (backend Module J).
///
/// NOTE: the backend currently exposes create/update/delete/pause/resume for
/// pharmacist-authored reminders but no GET list endpoint — so this screen
/// only tracks reminders created/edited during the current session rather
/// than fetching a persisted list. Once a listing endpoint exists, replace
/// [_reminders] with a real fetch on open.
class PatientRemindersScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientRemindersScreen({super.key, required this.patientId, required this.patientName});

  @override
  State<PatientRemindersScreen> createState() => _PatientRemindersScreenState();
}

class _PatientRemindersScreenState extends State<PatientRemindersScreen> {
  final List<ReminderScheduleEntity> _reminders = [];
  String? _busyId;

  Future<void> _openForm({ReminderScheduleEntity? existing}) async {
    final result = await Navigator.push<ReminderScheduleEntity>(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderFormScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
          existingReminder: existing,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      final index = _reminders.indexWhere((r) => r.id == result.id);
      if (index >= 0) {
        _reminders[index] = result;
      } else {
        _reminders.insert(0, result);
      }
    });
  }

  Future<void> _togglePause(ReminderScheduleEntity reminder) async {
    setState(() => _busyId = reminder.id);
    try {
      final repository = getIt<ReminderRepository>();
      final updated =
          reminder.isPaused ? await repository.resume(reminder.id) : await repository.pause(reminder.id);
      if (!mounted) return;
      setState(() {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index >= 0) _reminders[index] = updated;
        _busyId = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyId = null);
      _showError(e.statusCode == 404 ? 'لا توجد علاقة علاجية نشطة مع هذا المريض.' : e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyId = null);
      _showError('حدث خطأ غير متوقع، حاول مرة أخرى.');
    }
  }

  Future<void> _delete(ReminderScheduleEntity reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('حذف التذكير', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Text('هل أنت متأكد من حذف "${reminder.title}"؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('رجوع', style: GoogleFonts.cairo())),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('حذف', style: GoogleFonts.cairo(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyId = reminder.id);
    try {
      await getIt<ReminderRepository>().delete(reminder.id);
      if (!mounted) return;
      setState(() {
        _reminders.removeWhere((r) => r.id == reminder.id);
        _busyId = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyId = null);
      _showError(e.statusCode == 404 ? 'لا توجد علاقة علاجية نشطة مع هذا المريض.' : e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyId = null);
      _showError('حدث خطأ غير متوقع، حاول مرة أخرى.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.cairo()), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('تذكيرات ${widget.patientName}', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_alarm_rounded, color: Colors.white),
        label: Text('تذكير جديد', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _reminders.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  'لا توجد تذكيرات مضافة في هذه الجلسة بعد.\nاضغط "تذكير جديد" لإضافة أول تذكير لهذا المريض.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: AppColors.textSecondary),
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 90.h),
              itemCount: _reminders.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) => _reminderCard(_reminders[index]),
            ),
    );
  }

  Widget _reminderCard(ReminderScheduleEntity reminder) {
    final busy = _busyId == reminder.id;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reminder.title,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              if (reminder.isPaused)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text('متوقف', style: GoogleFonts.cairo(fontSize: 11.sp, color: AppColors.warning, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            _typeLabels[reminder.type] ?? reminder.type,
            style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          if (reminder.description != null && reminder.description!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(reminder.description!, style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.textSecondary)),
          ],
          SizedBox(height: 8.h),
          if (busy)
            const Align(alignment: Alignment.centerLeft, child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Wrap(
              spacing: 4.w,
              children: [
                TextButton.icon(
                  onPressed: () => _openForm(existing: reminder),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                  label: Text('تعديل', style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: () => _togglePause(reminder),
                  icon: Icon(reminder.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 16, color: AppColors.warning),
                  label: Text(
                    reminder.isPaused ? 'استئناف' : 'إيقاف مؤقت',
                    style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.warning, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _delete(reminder),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                  label: Text('حذف', style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.error, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
