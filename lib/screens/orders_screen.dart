import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import 'login_sheet.dart';
import 'cart_sheet.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import '../models/menu_item_model.dart';
import 'order_details_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _filter = 'All'; // All, Paid, Completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show login prompt if not authenticated
    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'My Orders',
            style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 20),
              Text(
                'Login to view your orders',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const LoginSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF62F56),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login / Register'),
              ),
            ],
          ),
        ),
      );
    }

    final ordersState = ref.watch(ordersProvider);

    // Filter logic
    final displayedOrders = ordersState.orders.where((order) {
      bool isPaid =
          order.paymentStatus == 'success' ||
          order.paymentStatus == 'completed';
      bool isActive = [
        'preparing',
        'ready',
        'completed',
      ].contains(order.status);

      // Hide unpaid pending orders
      if (!isPaid && !isActive) return false;

      if (_filter == 'All') return true;

      if (_filter == 'Paid') {
        // Only show paid orders that are NOT completed
        // (preparing, ready, or any paid order that's not completed)
        return isPaid && order.status != 'completed';
      }

      if (_filter == 'Completed') return order.status == 'completed';

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Global Cart Icon
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CartSheet(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Paid', 'Completed'].map((filter) {
                final isSelected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0x33F62F56),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFFF62F56)
                          : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _filter = filter;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ordersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(ordersProvider.notifier).fetchOrders();
                    },
                    child: displayedOrders.isEmpty
                        ? Stack(
                            children: [
                              ListView(), // Scrollable for refresh
                              Center(
                                child: Text(
                                  'No orders found',
                                  style: GoogleFonts.urbanist(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayedOrders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final order = displayedOrders[index];
                              return _buildOrderCard(context, order);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    Color statusColor = Colors.grey;
    if (order.status == 'completed') statusColor = Colors.green;
    if (order.status == 'ready') statusColor = Colors.orange;
    if (order.status == 'preparing') statusColor = Colors.blue;

    // Format Date: Dec 17, 2025 at 12:30 PM
    String formattedDate = order.createdAt;
    try {
      final date = DateTime.parse(order.createdAt).toLocal();
      formattedDate = DateFormat('MMM dd, yyyy \'at\' h:mm a').format(date);
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A9E9E9E),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderId}',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: GoogleFonts.urbanist(color: Colors.grey, fontSize: 12),
              ),
              Text(
                '₹${order.totalAmount}',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.items.length} Items',
                  style: GoogleFonts.urbanist(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(order: order),
                    ),
                  );
                },
                child: Text(
                  'View Details',
                  style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // Reorder Logic
                  final canteenId = order.canteenId is String
                      ? order.canteenId
                      : (order.canteenId as Map)['_id'];

                  final cartNotifier = ref.read(cartProvider.notifier);
                  cartNotifier.clearCart();

                  for (var item in order.items) {
                    final menuItem = MenuItem(
                      id: item.menuItemId,
                      name: item.name,
                      price: item.price,
                      availableQuantity: 99,
                      canteenId: canteenId,
                      image: '',
                    );
                    cartNotifier.addItem(menuItem, canteenId);
                    // Add remaining qty
                    for (int i = 0; i < item.quantity - 1; i++) {
                      cartNotifier.addItem(menuItem, canteenId);
                    }
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Items added to cart!')),
                  );
                },
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: Color(0xFFF62F56),
                ),
                label: Text(
                  'Reorder',
                  style: GoogleFonts.urbanist(
                    color: const Color(0xFFF62F56),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF62F56)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
