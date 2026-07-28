import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import '../../domain/entities/reminder_schedule_entity.dart';
import '../../domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ApiClient _apiClient;

  ReminderRepositoryImpl(this._apiClient);

  Map<String, dynamic> _body({
    required String type,
    String? relatedEntityId,
    required String title,
    String? description,
    required String frequencyType,
    int? intervalHours,
    required DateTime startTime,
    DateTime? endTime,
  }) {
    return {
      'type': type,
      if (relatedEntityId != null) 'relatedEntityId': relatedEntityId,
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'frequencyType': frequencyType,
      if (intervalHours != null) 'intervalHours': intervalHours,
      'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime.toIso8601String(),
    };
  }

  @override
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
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.createReminder(patientId),
      data: _body(
        type: type,
        relatedEntityId: relatedEntityId,
        title: title,
        description: description,
        frequencyType: frequencyType,
        intervalHours: intervalHours,
        startTime: startTime,
        endTime: endTime,
      ),
    );
    return unwrapApiResponse(
      response,
      (json) => ReminderScheduleEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
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
  }) async {
    final response = await _apiClient.dio.put(
      ApiConstants.updateReminder(scheduleId),
      data: _body(
        type: type,
        relatedEntityId: relatedEntityId,
        title: title,
        description: description,
        frequencyType: frequencyType,
        intervalHours: intervalHours,
        startTime: startTime,
        endTime: endTime,
      ),
    );
    return unwrapApiResponse(
      response,
      (json) => ReminderScheduleEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<void> delete(String scheduleId) async {
    await _apiClient.dio.delete(ApiConstants.deleteReminder(scheduleId));
  }

  @override
  Future<ReminderScheduleEntity> pause(String scheduleId) async {
    final response = await _apiClient.dio.put(ApiConstants.pauseReminder(scheduleId));
    return unwrapApiResponse(
      response,
      (json) => ReminderScheduleEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ReminderScheduleEntity> resume(String scheduleId) async {
    final response = await _apiClient.dio.put(ApiConstants.resumeReminder(scheduleId));
    return unwrapApiResponse(
      response,
      (json) => ReminderScheduleEntity.fromJson(json as Map<String, dynamic>),
    );
  }
}
