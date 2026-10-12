import '../../domain/entities/intern_patient_entity.dart';

abstract class InternPatientsState {}

class InternPatientsInitial extends InternPatientsState {}

class InternPatientsLoading extends InternPatientsState {}

class InternPatientsLoaded extends InternPatientsState {
  final List<InternPatientEntity> items;
  InternPatientsLoaded(this.items);
}

/// The intern has no active `InternshipAssignment` yet — their faculty
/// hasn't linked them to a supervisor. Same gate as the home screen's
/// progress card; not an error.
class InternPatientsNoAssignment extends InternPatientsState {}

class InternPatientsError extends InternPatientsState {
  final String message;
  InternPatientsError(this.message);
}

class InternPatientDetailLoading extends InternPatientsState {}

class InternPatientDetailLoaded extends InternPatientsState {
  final InternPatientEntity patient;
  final List<InternPatientPrescriptionEntity> prescriptions;
  final List<InternPatientMedicationPlanEntity> medicationPlans;

  InternPatientDetailLoaded({
    required this.patient,
    required this.prescriptions,
    required this.medicationPlans,
  });
}

class InternPatientDetailError extends InternPatientsState {
  final String message;
  InternPatientDetailError(this.message);
}
