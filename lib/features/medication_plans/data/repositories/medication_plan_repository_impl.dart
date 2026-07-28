import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import 'package:pharmacist/core/network/paged_result.dart';
import '../../domain/repositories/medication_plan_repository.dart';

class MedicationPlanRepositoryImpl implements MedicationPlanRepository {
  final ApiClient _apiClient;

  MedicationPlanRepositoryImpl(this._apiClient);

  @override
  Future<PagedResult<Map<String, dynamic>>> getAll({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.medicationPlans,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return unwrapApiResponse(
      response,
      (json) => PagedResult.fromJson(json, (item) => item),
    );
  }

  @override
  Future<Map<String, dynamic>> getById(String planId) async {
    final response = await _apiClient.dio.get(ApiConstants.medicationPlanDetail(planId));
    return unwrapApiResponse(response, (json) => json as Map<String, dynamic>);
  }

  Map<String, dynamic> _body({
    required String medicineName,
    required String dosage,
    String? instructions,
    int? quantity,
    String? prescribingDoctor,
    required String timeOfDay,
    required String frequency,
    required DateTime startDate,
    required int durationDays,
  }) {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      if (instructions != null && instructions.isNotEmpty) 'instructions': instructions,
      if (quantity != null) 'quantity': quantity,
      if (prescribingDoctor != null && prescribingDoctor.isNotEmpty)
        'prescribingDoctor': prescribingDoctor,
      'timeOfDay': timeOfDay,
      'frequency': frequency,
      'startDate': '${startDate.year.toString().padLeft(4, '0')}-'
          '${startDate.month.toString().padLeft(2, '0')}-'
          '${startDate.day.toString().padLeft(2, '0')}',
      'durationDays': durationDays,
    };
  }

  @override
  Future<Map<String, dynamic>> create({
    required String patientId,
    required String medicineName,
    required String dosage,
    String? instructions,
    int? quantity,
    String? prescribingDoctor,
    required String timeOfDay,
    required String frequency,
    required DateTime startDate,
    required int durationDays,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.createMedicationPlan,
      data: {
        'patientId': patientId,
        ..._body(
          medicineName: medicineName,
          dosage: dosage,
          instructions: instructions,
          quantity: quantity,
          prescribingDoctor: prescribingDoctor,
          timeOfDay: timeOfDay,
          frequency: frequency,
          startDate: startDate,
          durationDays: durationDays,
        ),
      },
    );
    return unwrapApiResponse(response, (json) => json as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> update(
    String planId, {
    required String medicineName,
    required String dosage,
    String? instructions,
    int? quantity,
    String? prescribingDoctor,
    required String timeOfDay,
    required String frequency,
    required DateTime startDate,
    required int durationDays,
  }) async {
    final response = await _apiClient.dio.put(
      ApiConstants.updateMedicationPlan(planId),
      data: _body(
        medicineName: medicineName,
        dosage: dosage,
        instructions: instructions,
        quantity: quantity,
        prescribingDoctor: prescribingDoctor,
        timeOfDay: timeOfDay,
        frequency: frequency,
        startDate: startDate,
        durationDays: durationDays,
      ),
    );
    return unwrapApiResponse(response, (json) => json as Map<String, dynamic>);
  }
}
