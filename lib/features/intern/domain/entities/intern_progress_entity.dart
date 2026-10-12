class InternProgressEntity {
  final String assignmentId;
  final String status;
  final double requiredHours;
  final double loggedHours;
  final double verifiedHours;
  final int targetPrescriptionReviews;
  final int targetMedicationPlans;
  final int prescriptionReviewDraftsSubmitted;
  final int medicationPlanDraftsSubmitted;
  final int draftsApproved;
  final int draftsPendingReview;

  InternProgressEntity({
    required this.assignmentId,
    required this.status,
    required this.requiredHours,
    required this.loggedHours,
    required this.verifiedHours,
    required this.targetPrescriptionReviews,
    required this.targetMedicationPlans,
    required this.prescriptionReviewDraftsSubmitted,
    required this.medicationPlanDraftsSubmitted,
    required this.draftsApproved,
    required this.draftsPendingReview,
  });
}
