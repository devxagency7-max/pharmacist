import '../../../../core/network/paged_result.dart';
import '../../domain/entities/order_entity.dart';

abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersQueueLoaded extends OrdersState {
  final PagedResult<OrderEntity> orders;
  final String status;

  OrdersQueueLoaded({
    required this.orders,
    required this.status,
  });
}

class OrdersActionSuccess extends OrdersState {
  final String message;
  OrdersActionSuccess(this.message);
}

class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
}
