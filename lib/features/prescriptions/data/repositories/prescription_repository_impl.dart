import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../models/prescription_model.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final ApiClient _apiClient;

  PrescriptionRepositoryImpl(this._apiClient);

  @override
  Future<PagedResult<PrescriptionEntity>> getPendingReviews({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.prescriptionsPending,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return unwrapApiResponse(
      response,
      (json) => PagedResult.fromJson(json, PrescriptionModel.fromJson),
    );
  }

  @override
  Future<PrescriptionEntity> getPrescriptionDetail(
    String prescriptionId,
  ) async {
    final response = await _apiClient.dio.get(
      ApiConstants.prescriptionDetail(prescriptionId),
    );
    return unwrapApiResponse(
      response,
      (json) => PrescriptionModel.fromJson(json),
    );
  }

  @override
  Future<void> approve(String prescriptionId, {String? notes}) async {
    await _apiClient.dio.post(
      ApiConstants.prescriptionApprove(prescriptionId),
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
  }

  @override
  Future<void> reject(String prescriptionId, {required String reason}) async {
    await _apiClient.dio.post(
      ApiConstants.prescriptionReject(prescriptionId),
      data: {'reason': reason},
    );
  }
}
