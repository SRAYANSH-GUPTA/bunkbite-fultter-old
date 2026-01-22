import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../models/order_model.dart';

class OrdersState {
  final bool isLoading;
  final List<OrderModel> orders;
  final String? error;

  OrdersState({this.isLoading = false, this.orders = const [], this.error});
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final ApiService _apiService;

  OrdersNotifier(this._apiService) : super(OrdersState());

  Future<void> fetchOrders() async {
    state = OrdersState(isLoading: true);
    try {
      final response = await _apiService.client.get('/orders');

      // Response format: { success: true, count: N, data: [...] }
      final List data = response.data['data'] ?? [];
      final orders = data.map((e) => OrderModel.fromJson(e)).toList();
      // Sort by newest first
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = OrdersState(isLoading: false, orders: orders);
    } catch (e) {
      state = OrdersState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> payForOrder(String orderId) async {
    try {
      await _apiService.client.post('/orders/$orderId/pay');
      return true;
    } catch (e) {
      return false;
    }
  }

  void clearOrders() {
    state = OrdersState();
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  return OrdersNotifier(ApiService());
});
