import '../../domain/entities/intern_supervisor_entity.dart';

class InternSupervisorModel extends InternSupervisorEntity {
  InternSupervisorModel({
    required super.supervisorName,
    super.supervisorEmail,
    super.supervisorPhone,
    super.syndicateLicenseNumber,
    super.yearsOfExperience,
    super.pharmacyName,
    super.branchName,
    super.assignmentStartDate,
    super.assignmentExpectedEndDate,
    required super.assignmentStatus,
  });

  factory InternSupervisorModel.fromJson(Map<String, dynamic> json) {
    return InternSupervisorModel(
      supervisorName: json['supervisorName'] ?? '',
      supervisorEmail: json['supervisorEmail'],
      supervisorPhone: json['supervisorPhone'],
      syndicateLicenseNumber: json['syndicateLicenseNumber'],
      yearsOfExperience: json['yearsOfExperience'] as int?,
      pharmacyName: json['pharmacyName'],
      branchName: json['branchName'],
      assignmentStartDate: DateTime.tryParse(json['assignmentStartDate'] ?? ''),
      assignmentExpectedEndDate:
          DateTime.tryParse(json['assignmentExpectedEndDate'] ?? ''),
      assignmentStatus: json['assignmentStatus'] ?? '',
    );
  }
}
