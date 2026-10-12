/// Shared shape for both GET /intern/my-patients (list item) and
/// GET /intern/my-patients/{id} (single detail) — backend confirms they're
/// identical.
class InternPatientEntity {
  final String patientUserId;
  final String name;
  final String email;
  final String? phone;
  final String riskLevel; // Low | Medium | High | Critical
  final int riskScore;
  final bool hasConversation;
  final int prescriptionDraftCount;
  final int medicationPlanDraftCount;
  final DateTime? lastInteractionAt;

  InternPatientEntity({
    required this.patientUserId,
    required this.name,
    required this.email,
    this.phone,
    required this.riskLevel,
    required this.riskScore,
    required this.hasConversation,
    required this.prescriptionDraftCount,
    required this.medicationPlanDraftCount,
    this.lastInteractionAt,
  });
}

/// GET /intern/my-patients/{id}/prescriptions item.
class InternPatientPrescriptionEntity {
  final String prescriptionId;
  final String? doctorName;
  final String? clinicName;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String status; // Valid | Expired | Used | Cancelled
  final DateTime createdAt;
  final String? myDraftId;
  final String? myDraftStatus; // PendingSupervisorReview | Approved | Rejected | null

  InternPatientPrescriptionEntity({
    required this.prescriptionId,
    this.doctorName,
    this.clinicName,
    this.issueDate,
    this.expiryDate,
    required this.status,
    required this.createdAt,
    this.myDraftId,
    this.myDraftStatus,
  });
}

/// GET /intern/my-patients/{id}/medication-plans item.
class InternPatientMedicationPlanEntity {
  final String medicationPlanId;
  final String medicineName;
  final String? dosage;
  final String? instructions;
  final int? quantity;
  final String? prescribingDoctor;
  final DateTime createdAt;
  final String? myDraftId;
  final String? myDraftStatus;

  InternPatientMedicationPlanEntity({
    required this.medicationPlanId,
    required this.medicineName,
    this.dosage,
    this.instructions,
    this.quantity,
    this.prescribingDoctor,
    required this.createdAt,
    this.myDraftId,
    this.myDraftStatus,
  });
}
