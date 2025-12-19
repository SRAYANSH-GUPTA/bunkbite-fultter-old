import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../core/api_service.dart';
import '../models/canteen_model.dart';
import '../models/menu_item_model.dart';
import 'package:dio/dio.dart';

class CanteenState {
  final bool isLoading;
  final List<Canteen> canteens;
  final Canteen? selectedCanteen;
  final List<MenuItem> menu;
  final String? error;

  CanteenState({
    this.isLoading = false,
    this.canteens = const [],
    this.selectedCanteen,
    this.menu = const [],
    this.error,
  });

  CanteenState copyWith({
    bool? isLoading,
    List<Canteen>? canteens,
    Canteen? selectedCanteen,
    List<MenuItem>? menu,
    String? error,
  }) {
    return CanteenState(
      isLoading: isLoading ?? this.isLoading,
      canteens: canteens ?? this.canteens,
      selectedCanteen: selectedCanteen ?? this.selectedCanteen,
      menu: menu ?? this.menu,
      error: error,
    );
  }
}

class CanteenNotifier extends StateNotifier<CanteenState> {
  final ApiService _apiService;

  CanteenNotifier(this._apiService) : super(CanteenState());

  Future<void> fetchCanteens() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.client.get(
        '/canteens',
      ); // Updated path
      // Response format: { success: true, count: N, data: [...] }
      final List data = response.data['data'] ?? [];

      final canteens = data.map((e) => Canteen.fromJson(e)).toList();

      state = state.copyWith(
        isLoading: false,
        canteens: canteens,
        // Update selectedCanteen to use fresh data if it exists
        selectedCanteen: state.selectedCanteen == null
            ? (canteens.isNotEmpty ? canteens.first : null)
            : canteens.firstWhere(
                (c) => c.id == state.selectedCanteen!.id,
                orElse: () => state
                    .selectedCanteen!, // Fallback to old if not found (deleted?)
              ),
      );

      if (state.selectedCanteen != null) {
        await fetchMenu(state.selectedCanteen!.id);
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> fetchMenu(String canteenId) async {
    // state = state.copyWith(isLoading: true); // Don't block whole UI, maybe just menu part
    // For now simple loading
    try {
      print('Fetching menu for canteen: $canteenId');
      final response = await _apiService.client.get('/menu/canteen/$canteenId');

      // Debug: Print full response
      print('Menu API Response: ${response.data}');

      // Response format: { success: true, data: [...] }
      final List data = response.data['data'] ?? [];
      print('Menu data array length: ${data.length}');

      if (data.isNotEmpty) {
        print('First menu item raw: ${data[0]}');
      }

      final menu = data.map((e) => MenuItem.fromJson(e)).toList();
      print('Menu loaded: ${menu.length} items');
      if (menu.isEmpty) {
        print('menu is not showing');
      }
      state = state.copyWith(menu: menu);
    } catch (e) {
      // If fails, maybe empty menu
      print('Error fetching menu: $e');
      state = state.copyWith(menu: []);
    }
  }

  void selectCanteen(Canteen canteen) {
    state = state.copyWith(selectedCanteen: canteen);
    fetchMenu(canteen.id);
  }

  Future<bool> addItem(String canteenId, Map<String, dynamic> itemData) async {
    try {
      // API: POST /menu/canteen/:canteenId
      await _apiService.client.post('/menu/canteen/$canteenId', data: itemData);
      await fetchMenu(canteenId); // Refresh menu
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateItem(String itemId, Map<String, dynamic> itemData) async {
    try {
      // API: PUT /menu/canteen/:canteenId/item/:itemId
      if (state.selectedCanteen == null) return false;
      await _apiService.client.put(
        '/menu/canteen/${state.selectedCanteen!.id}/item/$itemId',
        data: itemData,
      );
      // Refresh current menu
      await fetchMenu(state.selectedCanteen!.id);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      // API: DELETE /menu/canteen/:canteenId/item/:itemId
      if (state.selectedCanteen == null) return false;
      await _apiService.client.delete(
        '/menu/canteen/${state.selectedCanteen!.id}/item/$itemId',
      );
      await fetchMenu(state.selectedCanteen!.id);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> toggleCanteenStatus(String canteenId) async {
    try {
      // API: PATCH /canteens/:id/status (no body needed, just toggles)
      await _apiService.client.patch('/canteens/$canteenId/status');
      // Refresh list or selected canteen
      await fetchCanteens();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateCanteenHours(
    String canteenId,
    String open,
    String close,
  ) async {
    try {
      await _apiService.client.patch(
        '/canteens/$canteenId',
        data: {'openingTime': open, 'closingTime': close},
      );
      await fetchCanteens();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final canteenProvider = StateNotifierProvider<CanteenNotifier, CanteenState>((
  ref,
) {
  return CanteenNotifier(ApiService());
});
