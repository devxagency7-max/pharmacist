import '../../../../core/network/paged_result.dart';
import '../entities/order_entity.dart';

abstract class OrdersRepository {
  Future<PagedResult<OrderEntity>> getOrdersByBranch({
    required String branchId,
    int page = 1,
    int pageSize = 20,
    String? status, // Pending, Accepted, Completed, Rejected, Cancelled
  });

  Future<OrderEntity> respondToOrder({
    required String orderId,
    required String action, // accept, reject
    double? finalPrice,
    String? notes,
  });

  Future<OrderEntity> completeOrder({
    required String orderId,
  });

  Future<void> cancelOrder({
    required String orderId,
  });

  Future<OrderSummaryEntity> getOrderSummary({
    required String branchId,
  });
}
