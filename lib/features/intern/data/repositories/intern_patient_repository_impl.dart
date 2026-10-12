import 'package:dio/dio.dart';
import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import '../../domain/entities/intern_patient_entity.dart';
import '../../domain/repositories/intern_patient_repository.dart';
import '../models/intern_patient_model.dart';

class InternPatientRepositoryImpl implements InternPatientRepository {
  final ApiClient _apiClient;

  InternPatientRepositoryImpl(this._apiClient);

  @override
  Future<List<InternPatientEntity>?> getMyPatients() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.internMyPatients);
      return unwrapApiResponse(
        response,
        (json) => (json as List)
            .map((item) => InternPatientModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      // Every /intern/my-patients* endpoint requires an active
      // InternshipAssignment, same gate as progress/supervisor/program —
      // "No active internship assignment found for this account" is an
      // expected onboarding state, not an error.
      if (e.response?.statusCode == 403) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<InternPatientEntity> getPatientDetail(String patientUserId) async {
    final response = await _apiClient.dio.get(
      ApiConstants.internMyPatientDetail(patientUserId),
    );
    return unwrapApiResponse(
      response,
      (json) => InternPatientModel.fromJson(json),
    );
  }

  @override
  Future<List<InternPatientPrescriptionEntity>> getPatientPrescriptions(
    String patientUserId,
  ) async {
    final response = await _apiClient.dio.get(
      ApiConstants.internMyPatientPrescriptions(patientUserId),
    );
    return unwrapApiResponse(
      response,
      (json) => (json as List)
          .map((item) =>
              InternPatientPrescriptionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<List<InternPatientMedicationPlanEntity>> getPatientMedicationPlans(
    String patientUserId,
  ) async {
    final response = await _apiClient.dio.get(
      ApiConstants.internMyPatientMedicationPlans(patientUserId),
    );
    return unwrapApiResponse(
      response,
      (json) => (json as List)
          .map((item) =>
              InternPatientMedicationPlanModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
