import '../../domain/entities/pharmacist_application_entity.dart';

class PharmacistApplicationModel extends PharmacistApplicationEntity {
  PharmacistApplicationModel({
    required super.id,
    required super.userId,
    required super.applicationType,
    super.licenseNumber,
    super.universityName,
    super.universityId,
    super.facultyId,
    super.facultyName,
    required super.status,
    required super.submittedAt,
    super.rejectionReason,
  });

  factory PharmacistApplicationModel.fromJson(Map<String, dynamic> json) {
    return PharmacistApplicationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      applicationType: json['applicationType'] ?? '',
      licenseNumber: json['licenseNumber'],
      universityName: json['universityName'],
      universityId: json['universityId'],
      facultyId: json['facultyId'],
      facultyName: json['facultyName'],
      status: json['status'] ?? 'Pending',
      submittedAt: json['submittedAt'] ?? '',
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'applicationType': applicationType,
      'licenseNumber': licenseNumber,
      'universityName': universityName,
      'universityId': universityId,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'status': status,
      'submittedAt': submittedAt,
      'rejectionReason': rejectionReason,
    };
  }
}
