import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/repositories/orders_repository.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository _ordersRepository;

  OrdersBloc(this._ordersRepository) : super(OrdersInitial()) {
    on<OrdersLoadQueueRequested>(_onLoadQueue);
    on<OrdersRespondSubmitted>(_onRespond);
    on<OrdersCompleteSubmitted>(_onComplete);
    on<OrdersCancelSubmitted>(_onCancel);
  }

  Future<void> _onLoadQueue(
    OrdersLoadQueueRequested event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final result = await _ordersRepository.getOrdersByBranch(
        branchId: event.branchId,
        page: event.page,
        status: event.status,
      );
      emit(OrdersQueueLoaded(orders: result, status: event.status));
    } catch (e) {
      emit(OrdersError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onRespond(
    OrdersRespondSubmitted event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      await _ordersRepository.respondToOrder(
        orderId: event.orderId,
        action: event.action,
        finalPrice: event.finalPrice,
        notes: event.notes,
      );
      emit(OrdersActionSuccess(
        event.action.toLowerCase() == 'accept'
            ? 'تم قبول الطلب بنجاح'
            : 'تم رفض الطلب بنجاح',
      ));
      // Reload queue
      add(OrdersLoadQueueRequested(branchId: event.branchId, status: 'Pending'));
    } catch (e) {
      emit(OrdersError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onComplete(
    OrdersCompleteSubmitted event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      await _ordersRepository.completeOrder(orderId: event.orderId);
      emit(OrdersActionSuccess('تم إكمال الطلب بنجاح'));
      // Reload queue
      add(OrdersLoadQueueRequested(branchId: event.branchId, status: 'Accepted'));
    } catch (e) {
      emit(OrdersError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onCancel(
    OrdersCancelSubmitted event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      await _ordersRepository.cancelOrder(orderId: event.orderId);
      emit(OrdersActionSuccess('تم إلغاء الطلب بنجاح'));
      // Reload queue
      add(OrdersLoadQueueRequested(branchId: event.branchId, status: 'Pending'));
    } catch (e) {
      emit(OrdersError(mapErrorToMessage(e)));
    }
  }
}
