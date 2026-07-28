class OrderPrescriptionEntity {
  final String id;
  final String status;

  OrderPrescriptionEntity({
    required this.id,
    required this.status,
  });
}

class OrderItemEntity {
  final String id;
  final String medicineId;
  final int quantity;
  final String name;
  final String? dosage;
  final String? form;
  final String? warnings;
  final String? imageUrl;

  OrderItemEntity({
    required this.id,
    required this.medicineId,
    required this.quantity,
    required this.name,
    this.dosage,
    this.form,
    this.warnings,
    this.imageUrl,
  });
}

class OrderStatusHistoryEntity {
  final String status;
  final String? changedById;
  final String? comments;
  final String createdAt;

  OrderStatusHistoryEntity({
    required this.status,
    this.changedById,
    this.comments,
    required this.createdAt,
  });
}

class OrderEntity {
  final String id;
  final String customerId;
  final String customerName;
  final String pharmacyId;
  final String pharmacyName;
  final String branchId;
  final String branchName;
  final OrderPrescriptionEntity? prescription;
  final double? finalPrice;
  final String? respondedByPharmacyId;
  final String orderStatus;
  final String paymentStatus;
  final String? deliveryNotes;
  final List<OrderItemEntity> items;
  final List<OrderStatusHistoryEntity> statusHistory;
  final String createdAt;
  final String updatedAt;

  OrderEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.branchId,
    required this.branchName,
    this.prescription,
    this.finalPrice,
    this.respondedByPharmacyId,
    required this.orderStatus,
    required this.paymentStatus,
    this.deliveryNotes,
    required this.items,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
  });
}

class OrderSummaryEntity {
  final String branchId;
  final int total;
  final int pending;
  final int accepted;
  final int completed;
  final int rejected;
  final int cancelled;

  OrderSummaryEntity({
    required this.branchId,
    required this.total,
    required this.pending,
    required this.accepted,
    required this.completed,
    required this.rejected,
    required this.cancelled,
  });
}
