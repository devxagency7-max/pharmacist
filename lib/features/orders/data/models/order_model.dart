import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  OrderModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.pharmacyId,
    required super.pharmacyName,
    required super.branchId,
    required super.branchName,
    super.prescription,
    super.finalPrice,
    super.respondedByPharmacyId,
    required super.orderStatus,
    super.paymentStatus = '',
    super.deliveryNotes,
    required super.items,
    required super.statusHistory,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      pharmacyId: json['pharmacyId'] ?? '',
      pharmacyName: json['pharmacyName'] ?? '',
      branchId: json['branchId'] ?? '',
      branchName: json['branchName'] ?? '',
      prescription: json['prescription'] != null
          ? OrderPrescriptionModel.fromJson(json['prescription'])
          : null,
      finalPrice: json['finalPrice'] != null
          ? (json['finalPrice'] as num).toDouble()
          : null,
      respondedByPharmacyId: json['respondedByPharmacyId'],
      orderStatus: json['orderStatus'] ?? 'Pending',
      paymentStatus: json['paymentStatus'] ?? '',
      deliveryNotes: json['deliveryNotes'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItemModel.fromJson(item))
              .toList()
          : const [],
      statusHistory: json['statusHistory'] != null
          ? (json['statusHistory'] as List)
              .map((h) => OrderStatusHistoryModel.fromJson(h))
              .toList()
          : const [],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'branchId': branchId,
      'branchName': branchName,
      'prescription': prescription != null
          ? (prescription as OrderPrescriptionModel).toJson()
          : null,
      'finalPrice': finalPrice,
      'respondedByPharmacyId': respondedByPharmacyId,
      'orderStatus': orderStatus,
      'paymentStatus': paymentStatus,
      'deliveryNotes': deliveryNotes,
      'items': items.map((i) => (i as OrderItemModel).toJson()).toList(),
      'statusHistory':
          statusHistory.map((h) => (h as OrderStatusHistoryModel).toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class OrderPrescriptionModel extends OrderPrescriptionEntity {
  OrderPrescriptionModel({
    required super.id,
    required super.status,
  });

  factory OrderPrescriptionModel.fromJson(Map<String, dynamic> json) {
    return OrderPrescriptionModel(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
    };
  }
}

class OrderItemModel extends OrderItemEntity {
  OrderItemModel({
    required super.id,
    required super.medicineId,
    required super.quantity,
    required super.name,
    required super.dosage,
    required super.form,
    required super.warnings,
    super.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      medicineId: json['medicineId'] ?? '',
      quantity: json['quantity'] ?? 0,
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      form: json['form'] ?? '',
      warnings: json['warnings'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'quantity': quantity,
      'name': name,
      'dosage': dosage,
      'form': form,
      'warnings': warnings,
      'imageUrl': imageUrl,
    };
  }
}

class OrderStatusHistoryModel extends OrderStatusHistoryEntity {
  OrderStatusHistoryModel({
    required super.status,
    super.changedById,
    required super.comments,
    required super.createdAt,
  });

  factory OrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryModel(
      status: json['status'] ?? '',
      changedById: json['changedById'],
      comments: json['comments'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'changedById': changedById,
      'comments': comments,
      'createdAt': createdAt,
    };
  }
}

class OrderSummaryModel extends OrderSummaryEntity {
  OrderSummaryModel({
    required super.branchId,
    required super.total,
    required super.pending,
    required super.accepted,
    required super.completed,
    required super.rejected,
    required super.cancelled,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) {
    return OrderSummaryModel(
      branchId: json['branchId'] ?? '',
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      accepted: json['accepted'] ?? 0,
      completed: json['completed'] ?? 0,
      rejected: json['rejected'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'total': total,
      'pending': pending,
      'accepted': accepted,
      'completed': completed,
      'rejected': rejected,
      'cancelled': cancelled,
    };
  }
}
