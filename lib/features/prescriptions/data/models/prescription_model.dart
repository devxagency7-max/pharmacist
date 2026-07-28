import '../../domain/entities/prescription_entity.dart';

class PrescriptionModel extends PrescriptionEntity {
  PrescriptionModel({
    required super.id,
    required super.patientId,
    required super.patientName,
    super.doctorName,
    super.clinicName,
    super.issueDate,
    super.expiryDate,
    required super.status,
    required super.imageUrls,
    required super.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      doctorName: json['doctorName'],
      clinicName: json['clinicName'],
      issueDate: json['issueDate'] != null ? DateTime.tryParse(json['issueDate']) : null,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate']) : null,
      status: json['status'] ?? 'Pending',
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
