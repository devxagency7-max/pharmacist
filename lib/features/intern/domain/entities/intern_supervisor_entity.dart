class InternSupervisorEntity {
  final String supervisorName;
  final String? supervisorEmail;
  final String? supervisorPhone;
  final String? syndicateLicenseNumber;
  final int? yearsOfExperience;
  final String? pharmacyName;
  final String? branchName;
  final DateTime? assignmentStartDate;
  final DateTime? assignmentExpectedEndDate;
  final String assignmentStatus;

  InternSupervisorEntity({
    required this.supervisorName,
    this.supervisorEmail,
    this.supervisorPhone,
    this.syndicateLicenseNumber,
    this.yearsOfExperience,
    this.pharmacyName,
    this.branchName,
    this.assignmentStartDate,
    this.assignmentExpectedEndDate,
    required this.assignmentStatus,
  });
}
