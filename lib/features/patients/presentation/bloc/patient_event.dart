abstract class PatientEvent {}

class MyPatientsRequested extends PatientEvent {}

class PendingRequestsRequested extends PatientEvent {}

class PatientRequestRespondSubmitted extends PatientEvent {
  final String assignmentId;
  final bool accept;
  final String? rejectionReason;
  PatientRequestRespondSubmitted({
    required this.assignmentId,
    required this.accept,
    this.rejectionReason,
  });
}

class PatientDetailRequested extends PatientEvent {
  final String patientId;
  PatientDetailRequested(this.patientId);
}

class PatientTerminateSubmitted extends PatientEvent {
  final String patientId;
  PatientTerminateSubmitted(this.patientId);
}
