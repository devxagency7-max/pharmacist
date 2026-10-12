class InternDraftEntity {
  final String draftId;
  final String entityKind; // PrescriptionReview | MedicationPlan
  final String targetEntityId;
  final String status; // PendingSupervisorReview | Accepted | Rejected
  final String? internClinicalNotes;
  final String? supervisorFeedback;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  InternDraftEntity({
    required this.draftId,
    required this.entityKind,
    required this.targetEntityId,
    required this.status,
    this.internClinicalNotes,
    this.supervisorFeedback,
    required this.createdAt,
    this.reviewedAt,
  });
}
