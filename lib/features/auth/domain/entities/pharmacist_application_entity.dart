class PharmacistApplicationEntity {
  final String id;
  final String userId;
  final String applicationType;
  final String? licenseNumber;
  final String? universityName;
  final String status; // Pending, Approved, Rejected
  final String submittedAt;
  final String? rejectionReason;

  PharmacistApplicationEntity({
    required this.id,
    required this.userId,
    required this.applicationType,
    this.licenseNumber,
    this.universityName,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
  });
}
