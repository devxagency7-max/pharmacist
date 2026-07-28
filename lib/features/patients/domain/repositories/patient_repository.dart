import 'package:pharmacist/core/network/paged_result.dart';
import '../entities/patient_entity.dart';

abstract class PatientRepository {
  /// GET /pharmacists/pending-requests
  Future<PagedResult<AssignmentRequestEntity>> getPendingRequests({
    int page = 1,
    int pageSize = 20,
  });

  /// PUT /pharmacists/requests/{id}/respond
  Future<void> respondToRequest(
    String assignmentId, {
    required bool accept,
    String? rejectionReason,
  });

  /// GET /pharmacists/my-patients — Active assignments only, 10-min server cache.
  Future<PagedResult<PatientSummaryEntity>> getMyPatients({
    int page = 1,
    int pageSize = 20,
  });

  /// GET /pharmacists/patients/{id} — requires an Active assignment, 404 otherwise.
  Future<PatientDetailEntity> getPatientDetail(String patientId);

  /// PUT /pharmacists/patients/{id}/terminate
  Future<void> terminate(String patientId);
}
