abstract class OrdersEvent {}

class OrdersLoadQueueRequested extends OrdersEvent {
  final String branchId;
  final String status;
  final int page;

  OrdersLoadQueueRequested({
    required this.branchId,
    required this.status,
    this.page = 1,
  });
}

class OrdersRespondSubmitted extends OrdersEvent {
  final String branchId;
  final String orderId;
  final String action;
  final double? finalPrice;
  final String? notes;

  OrdersRespondSubmitted({
    required this.branchId,
    required this.orderId,
    required this.action,
    this.finalPrice,
    this.notes,
  });
}

class OrdersCompleteSubmitted extends OrdersEvent {
  final String branchId;
  final String orderId;

  OrdersCompleteSubmitted({
    required this.branchId,
    required this.orderId,
  });
}

class OrdersCancelSubmitted extends OrdersEvent {
  final String branchId;
  final String orderId;

  OrdersCancelSubmitted({
    required this.branchId,
    required this.orderId,
  });
}
