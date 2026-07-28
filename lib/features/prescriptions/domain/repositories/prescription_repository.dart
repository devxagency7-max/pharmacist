import '../entities/prescription_entity.dart';

abstract class PrescriptionRepository {
  /// GET /prescriptions/pending — FIFO (oldest first) queue of prescriptions
  /// awaiting review by any Pharmacist.
  Future<PagedResult<PrescriptionEntity>> getPendingReviews({
    int page = 1,
    int pageSize = 20,
  });

  /// GET /prescriptions/{id} — single prescription detail. Access is
  /// governed by IAccessControlService.CanAccessPrescriptionAsync (patient
  /// who owns it, or a pharmacist in context of a review); 404 if not
  /// found/not accessible.
  Future<PrescriptionEntity> getPrescriptionDetail(String prescriptionId);

  /// POST /prescriptions/{id}/approve
  Future<void> approve(String prescriptionId, {String? notes});

  /// POST /prescriptions/{id}/reject — reason is required by the backend.
  Future<void> reject(String prescriptionId, {required String reason});
}
