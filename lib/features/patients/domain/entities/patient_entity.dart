/// GET /pharmacists/my-patients item — active care relationships only.
class PatientSummaryEntity {
  final String patientId;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? gender;
  final DateTime? birthDate;
  final DateTime? assignedAt;
  final int medicalRecordsCount;
  final int medicationPlansCount;

  PatientSummaryEntity({
    required this.patientId,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.gender,
    this.birthDate,
    this.assignedAt,
    required this.medicalRecordsCount,
    required this.medicationPlansCount,
  });
}

/// GET /pharmacists/patients/{id} — requires an Active assignment.
class PatientDetailEntity extends PatientSummaryEntity {
  final String? phone;
  final List<dynamic> medicalRecords;
  final List<dynamic> healthReadings;
  final List<dynamic> medicationPlans;
  // The pharmacist↔patient conversation's real id, straight from the
  // backend — null if no conversation has been started with this patient
  // yet. Distinct from (and never overlapping with) the separate
  // patient-AI conversation id used by the ai-conversation endpoint.
  final String? conversationId;

  PatientDetailEntity({
    required super.patientId,
    required super.name,
    required super.email,
    this.phone,
    super.avatarUrl,
    super.gender,
    super.birthDate,
    super.assignedAt,
    required super.medicalRecordsCount,
    required super.medicationPlansCount,
    required this.medicalRecords,
    required this.healthReadings,
    required this.medicationPlans,
    this.conversationId,
  });
}

/// GET /pharmacists/pending-requests item — patient-initiated assignment
/// request awaiting this pharmacist's accept/reject.
class AssignmentRequestEntity {
  final String assignmentId;
  final String patientId;
  final String patientName;
  final String status;
  final String? patientNote;
  final String? rejectionReason;
  final DateTime? requestedAt;

  AssignmentRequestEntity({
    required this.assignmentId,
    required this.patientId,
    required this.patientName,
    required this.status,
    this.patientNote,
    this.rejectionReason,
    this.requestedAt,
  });
}
