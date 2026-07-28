import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import '../../../../core/network/paged_result.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../models/order_model.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final ApiClient _apiClient;

  OrdersRepositoryImpl(this._apiClient);

  @override
  Future<PagedResult<OrderEntity>> getOrdersByBranch({
    required String branchId,
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.ordersBranch(branchId),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return unwrapApiResponse(
      response,
      (json) => PagedResult.fromJson(json, OrderModel.fromJson),
    );
  }

  @override
  Future<OrderEntity> respondToOrder({
    required String orderId,
    required String action,
    double? finalPrice,
    String? notes,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.orderRespond(orderId),
      data: {
        'action': action,
        if (finalPrice != null) 'finalPrice': finalPrice,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return unwrapApiResponse(response, (json) => OrderModel.fromJson(json));
  }

  @override
  Future<OrderEntity> completeOrder({required String orderId}) async {
    final response = await _apiClient.dio.post(
      ApiConstants.orderComplete(orderId),
    );
    return unwrapApiResponse(response, (json) => OrderModel.fromJson(json));
  }

  @override
  Future<void> cancelOrder({required String orderId}) async {
    await _apiClient.dio.delete(
      ApiConstants.orderCancel(orderId),
    );
  }

  @override
  Future<OrderSummaryEntity> getOrderSummary({required String branchId}) async {
    final response = await _apiClient.dio.get(
      ApiConstants.ordersSummary,
      queryParameters: {'branchId': branchId},
    );
    return unwrapApiResponse(response, (json) => OrderSummaryModel.fromJson(json));
  }
}
