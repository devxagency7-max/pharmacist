import '../../domain/entities/patient_entity.dart';

class PatientSummaryModel extends PatientSummaryEntity {
  PatientSummaryModel({
    required super.patientId,
    required super.name,
    required super.email,
    super.avatarUrl,
    super.gender,
    super.birthDate,
    super.assignedAt,
    required super.medicalRecordsCount,
    required super.medicationPlansCount,
  });

  factory PatientSummaryModel.fromJson(Map<String, dynamic> json) {
    return PatientSummaryModel(
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      gender: json['gender'],
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
      assignedAt: json['assignedAt'] != null ? DateTime.tryParse(json['assignedAt']) : null,
      medicalRecordsCount: json['medicalRecordsCount'] ?? 0,
      medicationPlansCount: json['medicationPlansCount'] ?? 0,
    );
  }
}

class PatientDetailModel extends PatientDetailEntity {
  PatientDetailModel({
    required super.patientId,
    required super.name,
    required super.email,
    super.phone,
    super.avatarUrl,
    super.gender,
    super.birthDate,
    super.assignedAt,
    required super.medicalRecordsCount,
    required super.medicationPlansCount,
    required super.medicalRecords,
    required super.healthReadings,
    required super.medicationPlans,
    super.conversationId,
  });

  factory PatientDetailModel.fromJson(Map<String, dynamic> json) {
    return PatientDetailModel(
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      gender: json['gender'],
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
      assignedAt: json['assignedAt'] != null ? DateTime.tryParse(json['assignedAt']) : null,
      medicalRecordsCount: json['medicalRecordsCount'] ?? 0,
      medicationPlansCount: json['medicationPlansCount'] ?? 0,
      medicalRecords: json['medicalRecords'] ?? [],
      healthReadings: json['healthReadings'] ?? [],
      medicationPlans: json['medicationPlans'] ?? [],
      conversationId: json['conversationId'],
    );
  }
}

class AssignmentRequestModel extends AssignmentRequestEntity {
  AssignmentRequestModel({
    required super.assignmentId,
    required super.patientId,
    required super.patientName,
    required super.status,
    super.patientNote,
    super.rejectionReason,
    super.requestedAt,
  });

  factory AssignmentRequestModel.fromJson(Map<String, dynamic> json) {
    return AssignmentRequestModel(
      assignmentId: json['assignmentId'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      status: json['status'] ?? 'Pending',
      patientNote: json['patientNote'],
      rejectionReason: json['rejectionReason'],
      requestedAt: json['requestedAt'] != null ? DateTime.tryParse(json['requestedAt']) : null,
    );
  }
}
