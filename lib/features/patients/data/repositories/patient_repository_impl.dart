import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import 'package:pharmacist/core/network/paged_result.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/repositories/patient_repository.dart';
import '../models/patient_model.dart';

class PatientRepositoryImpl implements PatientRepository {
  final ApiClient _apiClient;

  PatientRepositoryImpl(this._apiClient);

  @override
  Future<PagedResult<AssignmentRequestEntity>> getPendingRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.pendingPatientRequests,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return unwrapApiResponse(
      response,
      (json) => PagedResult.fromJson(json, AssignmentRequestModel.fromJson),
    );
  }

  @override
  Future<void> respondToRequest(
    String assignmentId, {
    required bool accept,
    String? rejectionReason,
  }) async {
    await _apiClient.dio.put(
      ApiConstants.respondToPatientRequest(assignmentId),
      data: {
        'accept': accept,
        if (!accept && rejectionReason != null) 'rejectionReason': rejectionReason,
      },
    );
  }

  @override
  Future<PagedResult<PatientSummaryEntity>> getMyPatients({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.myPatients,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return unwrapApiResponse(
      response,
      (json) => PagedResult.fromJson(json, PatientSummaryModel.fromJson),
    );
  }

  @override
  Future<PatientDetailEntity> getPatientDetail(String patientId) async {
    final response = await _apiClient.dio.get(ApiConstants.patientDetail(patientId));
    return unwrapApiResponse(response, (json) => PatientDetailModel.fromJson(json));
  }

  @override
  Future<void> terminate(String patientId) async {
    await _apiClient.dio.put(ApiConstants.terminatePatient(patientId));
  }
}
