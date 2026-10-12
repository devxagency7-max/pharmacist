import '../entities/intern_progress_entity.dart';
import '../entities/intern_supervisor_entity.dart';
import '../entities/intern_program_entity.dart';
import '../entities/intern_draft_entity.dart';

abstract class InternRepository {
  /// GET /intern/progress — the intern's own assignment status, hours
  /// logged/required/verified, and draft counts. Returns null if the
  /// backend reports "No active internship assignment found for this
  /// account" (403) — that's an expected state, not an error, for an intern
  /// not yet placed with a supervisor by their faculty.
  Future<InternProgressEntity?> getProgress();

  /// GET /intern/my-supervisor — the supervisor/placement card. Same
  /// no-assignment-yet 403 → null handling as [getProgress].
  Future<InternSupervisorEntity?> getMySupervisor();

  /// GET /intern/my-program — the training program card. Same
  /// no-assignment-yet 403 → null handling as [getProgress].
  Future<InternProgramEntity?> getMyProgram();

  /// GET /intern/my-drafts — every draft the intern has submitted, oldest
  /// or newest first per backend default. [status] filters to
  /// PendingSupervisorReview | Accepted | Rejected when provided.
  Future<List<InternDraftEntity>> getMyDrafts({String? status});

  /// GET /intern/my-drafts/{id} — single draft detail.
  Future<InternDraftEntity> getDraftDetail(String draftId);

  /// POST /intern/activities/log-hours — self-reported training hours.
  Future<void> logTrainingHours({
    required DateTime date,
    required double hours,
    required String activityDescription,
  });

  /// POST /prescriptions/{id}/draft-recommendation — submit a draft review
  /// of an existing prescription for the intern's supervisor to accept or
  /// reject. Does not touch the real Prescription.
  Future<InternDraftEntity> draftPrescriptionRecommendation(
    String prescriptionId, {
    required String payloadJson,
    String? notes,
  });

  /// POST /medications/draft — submit a draft medication plan, either
  /// revising an existing plan (pass [existingMedicationPlanId]) or
  /// proposing a brand-new one (leave it null).
  Future<InternDraftEntity> draftMedicationPlan({
    String? existingMedicationPlanId,
    required String payloadJson,
    String? notes,
  });
}
