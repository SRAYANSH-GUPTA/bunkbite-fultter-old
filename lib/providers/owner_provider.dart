import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';
import '../models/order_model.dart';
import '../models/canteen_model.dart';
import '../models/menu_item_model.dart';

class OwnerState {
  final bool isLoading;
  final List<OrderModel> orders;
  final List<Canteen> myCanteens;
  final Canteen? selectedCanteen;
  final List<MenuItem> menu; // Add menu for selected canteen
  final Map<String, dynamic>? analyticsData;
  final String? error;

  OwnerState({
    this.isLoading = false,
    this.orders = const [],
    this.myCanteens = const [],
    this.selectedCanteen,
    this.menu = const [],
    this.analyticsData,
    this.error,
  });

  OwnerState copyWith({
    bool? isLoading,
    List<OrderModel>? orders,
    List<Canteen>? myCanteens,
    Canteen? selectedCanteen,
    List<MenuItem>? menu,
    String? error,
    Map<String, dynamic>? analyticsData,
  }) {
    return OwnerState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      myCanteens: myCanteens ?? this.myCanteens,
      selectedCanteen: selectedCanteen ?? this.selectedCanteen,
      menu: menu ?? this.menu,
      analyticsData: analyticsData ?? this.analyticsData,
      error: error,
    );
  }
}

class OwnerNotifier extends StateNotifier<OwnerState> {
  final ApiService _apiService;

  OwnerNotifier(this._apiService) : super(OwnerState());

  void selectCanteen(Canteen canteen) {
    // Immediately clear old data to prevent showing stale info
    state = state.copyWith(
      selectedCanteen: canteen,
      menu: [], // Clear menu immediately
      orders: [], // Clear orders immediately
    );

    // Then fetch fresh data
    fetchCanteenOrders(canteen.id);
    fetchCanteenMenu(canteen.id);
  }

  Future<void> fetchMyCanteens() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.client.get('/canteens/my-canteens');
      final List data = response.data['data'] ?? [];
      final canteens = data.map((e) => Canteen.fromJson(e)).toList();

      Canteen? selected = state.selectedCanteen;
      if (canteens.isNotEmpty && selected == null) {
        selected = canteens.first;
      } else if (selected != null &&
          !canteens.any((c) => c.id == selected?.id)) {
        selected = canteens.isNotEmpty ? canteens.first : null;
      }

      state = state.copyWith(
        isLoading: false,
        myCanteens: canteens,
        selectedCanteen: selected,
      );

      if (selected != null) {
        fetchCanteenOrders(selected.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createCanteen(String name, String place) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // API expects: name, place, ownerId, openingTime, closingTime
      // Extract ownerId from JWT token
      final token = storageService.getString(AppConstants.authTokenKey);
      String? ownerId;

      if (token != null) {
        try {
          final decoded = JwtDecoder.decode(token);
          ownerId = decoded['id'] ?? decoded['_id'];
        } catch (e) {
          // Token decode failed
        }
      }

      final data = {
        'name': name,
        'place': place,
        'openingTime': '09:00',
        'closingTime': '18:00',
      };

      // Add ownerId if we have it
      if (ownerId != null) {
        data['ownerId'] = ownerId;
      }

      await _apiService.client.post('/canteens', data: data);
      await fetchMyCanteens();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> fetchCanteenOrders(String canteenId) async {
    try {
      final response = await _apiService.client.get(
        '/orders/canteen/$canteenId',
      );
      final List data = response.data['data'] ?? [];
      final orders = data.map((e) => OrderModel.fromJson(e)).toList();
      state = state.copyWith(orders: orders);
    } catch (e) {
      // Error fetching orders
    }
  }

  Future<void> fetchAnalytics(String canteenId, {String period = 'day'}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.client.get(
        '/analytics/canteen/$canteenId',
        queryParameters: {'period': period},
      );

      final Map<String, dynamic> data = response.data['data'] ?? {};

      state = state.copyWith(isLoading: false, analyticsData: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _apiService.client.patch(
        '/orders/$orderId/status',
        data: {'status': newStatus},
      );
      // Optimistic update
      final updatedOrders = state.orders.map((o) {
        if (o.id == orderId) {
          // Assuming we'd have a copyWith on OrderModel, but for now just refreshing
          return o;
        }
        return o;
      }).toList();
      state = state.copyWith(orders: updatedOrders);

      if (state.selectedCanteen != null) {
        fetchCanteenOrders(state.selectedCanteen!.id);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> verifyQr(String qrData) async {
    try {
      await _apiService.client.post(
        '/orders/verify-qr',
        data: {'qrData': qrData},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<OrderModel?> fetchOrderById(String orderId) async {
    try {
      final response = await _apiService.client.get('/orders/$orderId');
      final data = response.data['data'] ?? response.data;
      return OrderModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> completePickup(String qrData) async {
    try {
      await _apiService.client.post('/orders/pickup', data: {'qrData': qrData});
      // Refresh orders after pickup
      if (state.selectedCanteen != null) {
        await fetchCanteenOrders(state.selectedCanteen!.id);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleCanteenStatus(bool isOpen) async {
    final canteen = state.selectedCanteen;
    if (canteen == null) return;

    try {
      // API: PATCH /canteens/:id/status (no body, just toggles)
      await _apiService.client.patch('/canteens/${canteen.id}/status');
      // Refresh canteens to get updated status
      await fetchMyCanteens();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Fetch menu for selected canteen
  Future<void> fetchCanteenMenu(String canteenId) async {
    try {
      final response = await _apiService.client.get('/menu/canteen/$canteenId');
      final List data = response.data['data'] ?? [];
      final menu = data.map((e) => MenuItem.fromJson(e)).toList();
      state = state.copyWith(menu: menu);
    } catch (e) {
      state = state.copyWith(menu: []);
    }
  }

  // Delete canteen
  Future<bool> deleteCanteen(String canteenId) async {
    try {
      await _apiService.client.delete('/canteens/$canteenId');
      await fetchMyCanteens();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Delete menu item
  Future<bool> deleteMenuItem(String canteenId, String itemId) async {
    try {
      await _apiService.client.delete('/menu/canteen/$canteenId/item/$itemId');
      await fetchCanteenMenu(canteenId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Add menu item
  Future<bool> addMenuItem(
    String canteenId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      await _apiService.client.post('/menu/canteen/$canteenId', data: itemData);
      await fetchCanteenMenu(canteenId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Update menu item
  Future<bool> updateMenuItem(
    String canteenId,
    String itemId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      await _apiService.client.put(
        '/menu/canteen/$canteenId/item/$itemId',
        data: itemData,
      );
      await fetchCanteenMenu(canteenId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final ownerProvider = StateNotifierProvider<OwnerNotifier, OwnerState>((ref) {
  return OwnerNotifier(ApiService());
});
