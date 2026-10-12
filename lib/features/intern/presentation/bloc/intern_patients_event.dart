abstract class InternPatientsEvent {}

class InternPatientsRequested extends InternPatientsEvent {}

class InternPatientDetailRequested extends InternPatientsEvent {
  final String patientUserId;
  InternPatientDetailRequested(this.patientUserId);
}
