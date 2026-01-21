import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../models/menu_item_model.dart';

class CartState {
  final Map<String, OrderLineItem> items; // Map menuItemId -> OrderLineItem
  final String? canteenId; // Cart must belong to one canteen

  CartState({this.items = const {}, this.canteenId});

  double get totalAmount =>
      items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get totalItems =>
      items.values.fold(0, (sum, item) => sum + item.quantity);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(MenuItem item, String canteenId) {
    // Check if adding from different canteen
    if (state.canteenId != null && state.canteenId != canteenId) {
      // For now, clear cart if canteen changes or throw error?
      // Prompt: "If user switches canteen, warn them that cart will be cleared."
      // We will clear it here for simplicity or handle in UI.
      // Let's assume UI handles warning, here we just force clear if mismatch for safety.
      state = CartState(canteenId: canteenId);
    }

    if (state.canteenId == null) {
      state = CartState(canteenId: canteenId, items: {});
    }

    final currentItems = Map<String, OrderLineItem>.from(state.items);

    // Check current quantity in cart
    final currentQuantity = currentItems.containsKey(item.id)
        ? currentItems[item.id]!.quantity
        : 0;

    // Validate: Don't allow adding more than available
    if (currentQuantity >= item.availableQuantity) {
      return; // Silently fail - UI should handle this
    }

    if (currentItems.containsKey(item.id)) {
      final existing = currentItems[item.id]!;
      currentItems[item.id] = OrderLineItem(
        menuItemId: existing.menuItemId,
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity + 1,
      );
    } else {
      currentItems[item.id] = OrderLineItem(
        menuItemId: item.id,
        name: item.name,
        price: item.price,
        quantity: 1,
      );
    }
    state = CartState(items: currentItems, canteenId: canteenId);
  }

  void removeItem(MenuItem item) {
    if (!state.items.containsKey(item.id)) return;

    final currentItems = Map<String, OrderLineItem>.from(state.items);
    final existing = currentItems[item.id]!;

    if (existing.quantity > 1) {
      currentItems[item.id] = OrderLineItem(
        menuItemId: existing.menuItemId,
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity - 1,
      );
    } else {
      currentItems.remove(item.id);
    }

    state = CartState(items: currentItems, canteenId: state.canteenId);

    if (currentItems.isEmpty) {
      clearCart();
    }
  }

  void incrementItem(String itemId) {
    if (!state.items.containsKey(itemId)) return;

    final currentItems = Map<String, OrderLineItem>.from(state.items);
    final existing = currentItems[itemId]!;

    currentItems[itemId] = OrderLineItem(
      menuItemId: existing.menuItemId,
      name: existing.name,
      price: existing.price,
      quantity: existing.quantity + 1,
    );
    state = CartState(items: currentItems, canteenId: state.canteenId);
  }

  void decrementItem(String itemId) {
    if (!state.items.containsKey(itemId)) return;

    final currentItems = Map<String, OrderLineItem>.from(state.items);
    final existing = currentItems[itemId]!;

    if (existing.quantity > 1) {
      currentItems[itemId] = OrderLineItem(
        menuItemId: existing.menuItemId,
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity - 1,
      );
    } else {
      currentItems.remove(itemId);
    }
    state = CartState(items: currentItems, canteenId: state.canteenId);

    if (currentItems.isEmpty) {
      clearCart();
    }
  }

  void clearCart() {
    state = CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
