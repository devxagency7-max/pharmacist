import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/api_exception.dart';
import '../../domain/repositories/prescription_repository.dart';
import 'prescription_event.dart';
import 'prescription_state.dart';

class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  final PrescriptionRepository _repository;

  PrescriptionBloc(this._repository) : super(PrescriptionInitial()) {
    on<PrescriptionQueueRequested>(_onQueueRequested);
    on<PrescriptionDetailRequested>(_onDetailRequested);
    on<PrescriptionApproveSubmitted>(_onApproveSubmitted);
    on<PrescriptionRejectSubmitted>(_onRejectSubmitted);
  }

  Future<void> _onQueueRequested(
    PrescriptionQueueRequested event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(PrescriptionQueueLoading());
    try {
      final result = await _repository.getPendingReviews();
      emit(PrescriptionQueueLoaded(result.items));
    } catch (e) {
      emit(PrescriptionQueueError(e is ApiException ? e.message : e.toString()));
    }
  }

  Future<void> _onDetailRequested(
    PrescriptionDetailRequested event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(PrescriptionDetailLoading());
    try {
      final prescription = await _repository.getPrescriptionDetail(event.prescriptionId);
      emit(PrescriptionDetailLoaded(prescription));
    } catch (e) {
      emit(PrescriptionDetailError(e is ApiException ? e.message : e.toString()));
    }
  }

  Future<void> _onApproveSubmitted(
    PrescriptionApproveSubmitted event,
    Emitter<PrescriptionState> emit,
  ) async {
    try {
      await _repository.approve(event.prescriptionId, notes: event.notes);
      emit(PrescriptionActionSuccess('تمت الموافقة على الوصفة الطبية.'));
      add(PrescriptionQueueRequested());
    } catch (e) {
      emit(PrescriptionActionError(e is ApiException ? e.message : e.toString()));
    }
  }

  Future<void> _onRejectSubmitted(
    PrescriptionRejectSubmitted event,
    Emitter<PrescriptionState> emit,
  ) async {
    try {
      await _repository.reject(event.prescriptionId, reason: event.reason);
      emit(PrescriptionActionSuccess('تم رفض الوصفة الطبية.'));
      add(PrescriptionQueueRequested());
    } catch (e) {
      emit(PrescriptionActionError(e is ApiException ? e.message : e.toString()));
    }
  }
}
