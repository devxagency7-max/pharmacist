import '../../domain/entities/intern_progress_entity.dart';

class InternProgressModel extends InternProgressEntity {
  InternProgressModel({
    required super.assignmentId,
    required super.status,
    required super.requiredHours,
    required super.loggedHours,
    required super.verifiedHours,
    required super.targetPrescriptionReviews,
    required super.targetMedicationPlans,
    required super.prescriptionReviewDraftsSubmitted,
    required super.medicationPlanDraftsSubmitted,
    required super.draftsApproved,
    required super.draftsPendingReview,
  });

  factory InternProgressModel.fromJson(Map<String, dynamic> json) {
    return InternProgressModel(
      assignmentId: json['assignmentId'] ?? '',
      status: json['status'] ?? '',
      requiredHours: (json['requiredHours'] ?? 0).toDouble(),
      loggedHours: (json['loggedHours'] ?? 0).toDouble(),
      verifiedHours: (json['verifiedHours'] ?? 0).toDouble(),
      targetPrescriptionReviews: (json['targetPrescriptionReviews'] ?? 0) as int,
      targetMedicationPlans: (json['targetMedicationPlans'] ?? 0) as int,
      prescriptionReviewDraftsSubmitted:
          (json['prescriptionReviewDraftsSubmitted'] ?? 0) as int,
      medicationPlanDraftsSubmitted:
          (json['medicationPlanDraftsSubmitted'] ?? 0) as int,
      draftsApproved: (json['draftsApproved'] ?? 0) as int,
      draftsPendingReview: (json['draftsPendingReview'] ?? 0) as int,
    );
  }
}
