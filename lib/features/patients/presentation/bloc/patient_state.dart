import '../../domain/entities/patient_entity.dart';

abstract class PatientState {}

class PatientInitial extends PatientState {}

class MyPatientsLoading extends PatientState {}

class MyPatientsLoaded extends PatientState {
  final List<PatientSummaryEntity> items;
  MyPatientsLoaded(this.items);
}

class MyPatientsError extends PatientState {
  final String message;
  MyPatientsError(this.message);
}

class PendingRequestsLoading extends PatientState {}

class PendingRequestsLoaded extends PatientState {
  final List<AssignmentRequestEntity> items;
  PendingRequestsLoaded(this.items);
}

class PendingRequestsError extends PatientState {
  final String message;
  PendingRequestsError(this.message);
}

class PatientRequestActionSuccess extends PatientState {
  final String message;
  PatientRequestActionSuccess(this.message);
}

class PatientRequestActionError extends PatientState {
  final String message;
  PatientRequestActionError(this.message);
}

class PatientDetailLoading extends PatientState {}

class PatientDetailLoaded extends PatientState {
  final PatientDetailEntity patient;
  PatientDetailLoaded(this.patient);
}

class PatientDetailError extends PatientState {
  final String message;
  PatientDetailError(this.message);
}

class PatientTerminateSuccess extends PatientState {}

class PatientTerminateError extends PatientState {
  final String message;
  PatientTerminateError(this.message);
}
