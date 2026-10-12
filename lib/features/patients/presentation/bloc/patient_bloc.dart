import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/repositories/patient_repository.dart';
import 'patient_event.dart';
import 'patient_state.dart';

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final PatientRepository _repository;

  PatientBloc(this._repository) : super(PatientInitial()) {
    on<MyPatientsRequested>(_onMyPatientsRequested);
    on<PendingRequestsRequested>(_onPendingRequestsRequested);
    on<PatientRequestRespondSubmitted>(_onRespondSubmitted);
    on<PatientDetailRequested>(_onDetailRequested);
    on<PatientTerminateSubmitted>(_onTerminateSubmitted);
  }

  Future<void> _onMyPatientsRequested(
    MyPatientsRequested event,
    Emitter<PatientState> emit,
  ) async {
    emit(MyPatientsLoading());
    try {
      final result = await _repository.getMyPatients();
      emit(MyPatientsLoaded(result.items));
    } catch (e) {
      emit(MyPatientsError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onPendingRequestsRequested(
    PendingRequestsRequested event,
    Emitter<PatientState> emit,
  ) async {
    emit(PendingRequestsLoading());
    try {
      final result = await _repository.getPendingRequests();
      emit(PendingRequestsLoaded(result.items));
    } catch (e) {
      emit(PendingRequestsError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onRespondSubmitted(
    PatientRequestRespondSubmitted event,
    Emitter<PatientState> emit,
  ) async {
    try {
      await _repository.respondToRequest(
        event.assignmentId,
        accept: event.accept,
        rejectionReason: event.rejectionReason,
      );
      emit(PatientRequestActionSuccess(
        event.accept ? 'تم قبول طلب المريض.' : 'تم رفض طلب المريض.',
      ));
      add(PendingRequestsRequested());
    } catch (e) {
      emit(PatientRequestActionError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onDetailRequested(
    PatientDetailRequested event,
    Emitter<PatientState> emit,
  ) async {
    emit(PatientDetailLoading());
    try {
      final patient = await _repository.getPatientDetail(event.patientId);
      emit(PatientDetailLoaded(patient));
    } catch (e) {
      emit(PatientDetailError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onTerminateSubmitted(
    PatientTerminateSubmitted event,
    Emitter<PatientState> emit,
  ) async {
    try {
      await _repository.terminate(event.patientId);
      emit(PatientTerminateSuccess());
    } catch (e) {
      emit(PatientTerminateError(mapErrorToMessage(e)));
    }
  }
}
