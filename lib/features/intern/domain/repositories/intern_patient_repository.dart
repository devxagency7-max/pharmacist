import '../entities/intern_patient_entity.dart';

abstract class InternPatientRepository {
  /// GET /intern/my-patients — patients the intern has interacted with
  /// (chat, prescription draft, or medication-plan draft), newest
  /// interaction first. Returns null if the backend reports "No active
  /// internship assignment found for this account" (403) — an expected
  /// onboarding state, not an error. An empty (non-null) list means the
  /// intern has an active assignment but no patient interactions yet.
  Future<List<InternPatientEntity>?> getMyPatients();

  /// GET /intern/my-patients/{id} — single patient detail.
  Future<InternPatientEntity> getPatientDetail(String patientUserId);

  /// GET /intern/my-patients/{id}/prescriptions
  Future<List<InternPatientPrescriptionEntity>> getPatientPrescriptions(
    String patientUserId,
  );

  /// GET /intern/my-patients/{id}/medication-plans
  Future<List<InternPatientMedicationPlanEntity>> getPatientMedicationPlans(
    String patientUserId,
  );
}
