class InternProgramEntity {
  final String programName;
  final String? academicYear;
  final String? semester;
  final String? facultyName;
  final String? universityName;
  final double requiredTrainingHours;
  final int targetPrescriptionReviews;
  final int targetMedicationPlans;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  InternProgramEntity({
    required this.programName,
    this.academicYear,
    this.semester,
    this.facultyName,
    this.universityName,
    required this.requiredTrainingHours,
    required this.targetPrescriptionReviews,
    required this.targetMedicationPlans,
    this.startDate,
    this.endDate,
    required this.status,
  });
}
