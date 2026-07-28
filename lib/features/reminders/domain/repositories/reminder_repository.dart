import '../entities/reminder_schedule_entity.dart';

abstract class ReminderRepository {
  /// POST /pharmacists/patients/{patientId}/reminders
  Future<ReminderScheduleEntity> create({
    required String patientId,
    required String type,
    String? relatedEntityId,
    required String title,
    String? description,
    required String frequencyType,
    int? intervalHours,
    required DateTime startTime,
    DateTime? endTime,
  });

  /// PUT /pharmacists/reminders/{scheduleId}
  Future<ReminderScheduleEntity> update(
    String scheduleId, {
    required String type,
    String? relatedEntityId,
    required String title,
    String? description,
    required String frequencyType,
    int? intervalHours,
    required DateTime startTime,
    DateTime? endTime,
  });

  /// DELETE /pharmacists/reminders/{scheduleId}
  Future<void> delete(String scheduleId);

  /// PUT /pharmacists/reminders/{scheduleId}/pause
  Future<ReminderScheduleEntity> pause(String scheduleId);

  /// PUT /pharmacists/reminders/{scheduleId}/resume
  Future<ReminderScheduleEntity> resume(String scheduleId);
}
