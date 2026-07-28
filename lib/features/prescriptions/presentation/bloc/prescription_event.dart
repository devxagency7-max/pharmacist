abstract class PrescriptionEvent {}

/// Load (or refresh) the pending-review queue from page 1.
class PrescriptionQueueRequested extends PrescriptionEvent {}

/// GET /prescriptions/{id} — fetch fresh detail for one prescription
/// (used when opening a prescription from the queue, so the detail screen
/// isn't limited to whatever fields the list response happened to include).
class PrescriptionDetailRequested extends PrescriptionEvent {
  final String prescriptionId;
  PrescriptionDetailRequested(this.prescriptionId);
}

class PrescriptionApproveSubmitted extends PrescriptionEvent {
  final String prescriptionId;
  final String? notes;
  PrescriptionApproveSubmitted({required this.prescriptionId, this.notes});
}

class PrescriptionRejectSubmitted extends PrescriptionEvent {
  final String prescriptionId;
  final String reason;
  PrescriptionRejectSubmitted({required this.prescriptionId, required this.reason});
}
