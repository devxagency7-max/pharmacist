import 'package:pharmacist/core/network/paged_result.dart';

abstract class MedicationPlanRepository {
  /// GET /medications?page=&pageSize= — all plans authored by this pharmacist.
  Future<PagedResult<Map<String, dynamic>>> getAll({
    int page = 1,
    int pageSize = 20,
  });

  /// GET /medications/{id}
  Future<Map<String, dynamic>> getById(String planId);

  /// POST /medications
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
  });

  /// PUT /medications/{id}
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
  });
}
