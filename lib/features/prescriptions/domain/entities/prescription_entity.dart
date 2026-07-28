export '../../../../core/network/paged_result.dart';

class PrescriptionEntity {
  final String id;
  final String patientId;
  final String patientName;
  final String? doctorName;
  final String? clinicName;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String status;
  final List<String> imageUrls;
  final DateTime createdAt;

  PrescriptionEntity({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.doctorName,
    this.clinicName,
    this.issueDate,
    this.expiryDate,
    required this.status,
    required this.imageUrls,
    required this.createdAt,
  });
}
