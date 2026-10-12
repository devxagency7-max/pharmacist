import '../../domain/entities/intern_program_entity.dart';

class InternProgramModel extends InternProgramEntity {
  InternProgramModel({
    required super.programName,
    super.academicYear,
    super.semester,
    super.facultyName,
    super.universityName,
    required super.requiredTrainingHours,
    required super.targetPrescriptionReviews,
    required super.targetMedicationPlans,
    super.startDate,
    super.endDate,
    required super.status,
  });

  factory InternProgramModel.fromJson(Map<String, dynamic> json) {
    return InternProgramModel(
      programName: json['programName'] ?? '',
      academicYear: json['academicYear'],
      semester: json['semester'],
      facultyName: json['facultyName'],
      universityName: json['universityName'],
      requiredTrainingHours: (json['requiredTrainingHours'] ?? 0).toDouble(),
      targetPrescriptionReviews: (json['targetPrescriptionReviews'] ?? 0) as int,
      targetMedicationPlans: (json['targetMedicationPlans'] ?? 0) as int,
      startDate: DateTime.tryParse(json['startDate'] ?? ''),
      endDate: DateTime.tryParse(json['endDate'] ?? ''),
      status: json['status'] ?? '',
    );
  }
}
