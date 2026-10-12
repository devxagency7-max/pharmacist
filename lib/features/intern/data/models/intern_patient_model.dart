import '../../domain/entities/intern_patient_entity.dart';

class InternPatientModel extends InternPatientEntity {
  InternPatientModel({
    required super.patientUserId,
    required super.name,
    required super.email,
    super.phone,
    required super.riskLevel,
    required super.riskScore,
    required super.hasConversation,
    required super.prescriptionDraftCount,
    required super.medicationPlanDraftCount,
    super.lastInteractionAt,
  });

  factory InternPatientModel.fromJson(Map<String, dynamic> json) {
    return InternPatientModel(
      patientUserId: json['patientUserId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      riskLevel: json['riskLevel'] ?? 'Low',
      riskScore: (json['riskScore'] ?? 0) as int,
      hasConversation: json['hasConversation'] ?? false,
      prescriptionDraftCount: (json['prescriptionDraftCount'] ?? 0) as int,
      medicationPlanDraftCount: (json['medicationPlanDraftCount'] ?? 0) as int,
      lastInteractionAt: DateTime.tryParse(json['lastInteractionAt'] ?? ''),
    );
  }
}

class InternPatientPrescriptionModel extends InternPatientPrescriptionEntity {
  InternPatientPrescriptionModel({
    required super.prescriptionId,
    super.doctorName,
    super.clinicName,
    super.issueDate,
    super.expiryDate,
    required super.status,
    required super.createdAt,
    super.myDraftId,
    super.myDraftStatus,
  });

  factory InternPatientPrescriptionModel.fromJson(Map<String, dynamic> json) {
    return InternPatientPrescriptionModel(
      prescriptionId: json['prescriptionId'] ?? '',
      doctorName: json['doctorName'],
      clinicName: json['clinicName'],
      issueDate: DateTime.tryParse(json['issueDate'] ?? ''),
      expiryDate: DateTime.tryParse(json['expiryDate'] ?? ''),
      status: json['status'] ?? 'Valid',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      myDraftId: json['myDraftId'],
      myDraftStatus: json['myDraftStatus'],
    );
  }
}

class InternPatientMedicationPlanModel extends InternPatientMedicationPlanEntity {
  InternPatientMedicationPlanModel({
    required super.medicationPlanId,
    required super.medicineName,
    super.dosage,
    super.instructions,
    super.quantity,
    super.prescribingDoctor,
    required super.createdAt,
    super.myDraftId,
    super.myDraftStatus,
  });

  factory InternPatientMedicationPlanModel.fromJson(Map<String, dynamic> json) {
    return InternPatientMedicationPlanModel(
      medicationPlanId: json['medicationPlanId'] ?? '',
      medicineName: json['medicineName'] ?? '',
      dosage: json['dosage'],
      instructions: json['instructions'],
      quantity: json['quantity'] as int?,
      prescribingDoctor: json['prescribingDoctor'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      myDraftId: json['myDraftId'],
      myDraftStatus: json['myDraftStatus'],
    );
  }
}
