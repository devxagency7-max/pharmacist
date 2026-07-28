class DashboardMetricsEntity {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double successRate;

  DashboardMetricsEntity({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.successRate,
  });
}

class OrderDistributionEntity {
  final int withPrescription;
  final int withoutPrescription;

  OrderDistributionEntity({
    required this.withPrescription,
    required this.withoutPrescription,
  });
}

class FulfillmentTrendEntity {
  final int year;
  final int month;
  final int completedCount;

  FulfillmentTrendEntity({
    required this.year,
    required this.month,
    required this.completedCount,
  });
}

class TopMedicationEntity {
  final String medicineId;
  final String name;
  final int orderItemCount;

  TopMedicationEntity({
    required this.medicineId,
    required this.name,
    required this.orderItemCount,
  });
}

class RejectionNoteEntity {
  final String orderId;
  final String reason;
  final String? rejectedAt;

  RejectionNoteEntity({
    required this.orderId,
    required this.reason,
    this.rejectedAt,
  });
}

class DashboardDataEntity {
  final DashboardMetricsEntity metrics;
  final OrderDistributionEntity distribution;
  final List<FulfillmentTrendEntity> trend;
  final List<TopMedicationEntity> topMedications;
  final List<RejectionNoteEntity> rejectionNotes;

  DashboardDataEntity({
    required this.metrics,
    required this.distribution,
    required this.trend,
    required this.topMedications,
    required this.rejectionNotes,
  });
}
