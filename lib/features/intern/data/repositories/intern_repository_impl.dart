import 'package:dio/dio.dart';
import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import '../../domain/entities/intern_progress_entity.dart';
import '../../domain/entities/intern_supervisor_entity.dart';
import '../../domain/entities/intern_program_entity.dart';
import '../../domain/entities/intern_draft_entity.dart';
import '../../domain/repositories/intern_repository.dart';
import '../models/intern_progress_model.dart';
import '../models/intern_supervisor_model.dart';
import '../models/intern_program_model.dart';
import '../models/intern_draft_model.dart';

class InternRepositoryImpl implements InternRepository {
  final ApiClient _apiClient;

  InternRepositoryImpl(this._apiClient);

  @override
  Future<InternProgressEntity?> getProgress() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.internProgress);
      return unwrapApiResponse(
        response,
        (json) => InternProgressModel.fromJson(json),
      );
    } on DioException catch (e) {
      // "No active internship assignment found for this account" — expected
      // state while the intern's faculty hasn't assigned a supervisor yet.
      if (e.response?.statusCode == 403) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<InternSupervisorEntity?> getMySupervisor() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.internMySupervisor);
      return unwrapApiResponse(
        response,
        (json) => InternSupervisorModel.fromJson(json),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<InternProgramEntity?> getMyProgram() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.internMyProgram);
      return unwrapApiResponse(
        response,
        (json) => InternProgramModel.fromJson(json),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<InternDraftEntity>> getMyDrafts({String? status}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.internMyDrafts,
        queryParameters: {if (status != null) 'status': status},
      );
      return unwrapApiResponse(
        response,
        (json) => (json as List)
            .map((item) => InternDraftModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      // Same "No active internship assignment" gate as progress/supervisor/
      // program — no assignment means no drafts yet, not an error.
      if (e.response?.statusCode == 403) {
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<InternDraftEntity> getDraftDetail(String draftId) async {
    final response = await _apiClient.dio.get(
      ApiConstants.internMyDraftDetail(draftId),
    );
    return unwrapApiResponse(
      response,
      (json) => InternDraftModel.fromJson(json),
    );
  }

  @override
  Future<void> logTrainingHours({
    required DateTime date,
    required double hours,
    required String activityDescription,
  }) async {
    await _apiClient.dio.post(
      ApiConstants.internLogHours,
      data: {
        'date': date.toIso8601String().split('T').first,
        'hours': hours,
        'activityDescription': activityDescription,
      },
    );
  }

  @override
  Future<InternDraftEntity> draftPrescriptionRecommendation(
    String prescriptionId, {
    required String payloadJson,
    String? notes,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.prescriptionDraftRecommendation(prescriptionId),
      data: {
        'payloadJson': payloadJson,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return unwrapApiResponse(
      response,
      (json) => InternDraftModel.fromJson(json),
    );
  }

  @override
  Future<InternDraftEntity> draftMedicationPlan({
    String? existingMedicationPlanId,
    required String payloadJson,
    String? notes,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.medicationDraft,
      data: {
        if (existingMedicationPlanId != null &&
            existingMedicationPlanId.isNotEmpty)
          'existingMedicationPlanId': existingMedicationPlanId,
        'payloadJson': payloadJson,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return unwrapApiResponse(
      response,
      (json) => InternDraftModel.fromJson(json),
    );
  }
}
