import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/entities/intern_patient_entity.dart';
import '../../domain/repositories/intern_patient_repository.dart';
import 'intern_patients_event.dart';
import 'intern_patients_state.dart';

class InternPatientsBloc extends Bloc<InternPatientsEvent, InternPatientsState> {
  final InternPatientRepository _repository;

  InternPatientsBloc(this._repository) : super(InternPatientsInitial()) {
    on<InternPatientsRequested>(_onPatientsRequested);
    on<InternPatientDetailRequested>(_onPatientDetailRequested);
  }

  Future<void> _onPatientsRequested(
    InternPatientsRequested event,
    Emitter<InternPatientsState> emit,
  ) async {
    emit(InternPatientsLoading());
    try {
      final items = await _repository.getMyPatients();
      if (items == null) {
        emit(InternPatientsNoAssignment());
      } else {
        emit(InternPatientsLoaded(items));
      }
    } catch (e) {
      emit(InternPatientsError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onPatientDetailRequested(
    InternPatientDetailRequested event,
    Emitter<InternPatientsState> emit,
  ) async {
    emit(InternPatientDetailLoading());
    try {
      final patientFuture = _repository.getPatientDetail(event.patientUserId);
      final prescriptionsFuture =
          _repository.getPatientPrescriptions(event.patientUserId);
      final plansFuture =
          _repository.getPatientMedicationPlans(event.patientUserId);

      final InternPatientEntity patient = await patientFuture;
      final List<InternPatientPrescriptionEntity> prescriptions =
          await prescriptionsFuture;
      final List<InternPatientMedicationPlanEntity> plans = await plansFuture;

      emit(
        InternPatientDetailLoaded(
          patient: patient,
          prescriptions: prescriptions,
          medicationPlans: plans,
        ),
      );
    } catch (e) {
      emit(InternPatientDetailError(mapErrorToMessage(e)));
    }
  }
}
