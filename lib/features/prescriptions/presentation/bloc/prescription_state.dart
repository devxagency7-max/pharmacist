import '../../domain/entities/prescription_entity.dart';

abstract class PrescriptionState {}

class PrescriptionInitial extends PrescriptionState {}

class PrescriptionQueueLoading extends PrescriptionState {}

class PrescriptionQueueLoaded extends PrescriptionState {
  final List<PrescriptionEntity> items;
  PrescriptionQueueLoaded(this.items);
}

class PrescriptionQueueError extends PrescriptionState {
  final String message;
  PrescriptionQueueError(this.message);
}

class PrescriptionDetailLoading extends PrescriptionState {}

class PrescriptionDetailLoaded extends PrescriptionState {
  final PrescriptionEntity prescription;
  PrescriptionDetailLoaded(this.prescription);
}

class PrescriptionDetailError extends PrescriptionState {
  final String message;
  PrescriptionDetailError(this.message);
}

/// Emitted right after a successful approve/reject, before the queue is
/// reloaded, so the UI can show a confirmation (e.g. a SnackBar).
class PrescriptionActionSuccess extends PrescriptionState {
  final String message;
  PrescriptionActionSuccess(this.message);
}

class PrescriptionActionError extends PrescriptionState {
  final String message;
  PrescriptionActionError(this.message);
}
