import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/owner_provider.dart';
import 'scanner_screen.dart';

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ownerProvider.notifier).fetchMyCanteens();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ownerState = ref.watch(ownerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(ownerProvider.notifier).fetchMyCanteens();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );
        },
        label: const Text('Scan QR'),
        icon: const Icon(Icons.qr_code_scanner),
        backgroundColor: const Color(0xFFF62F56),
        foregroundColor: Colors.white,
      ),
      body: ownerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ownerState.orders.isEmpty
          ? Center(
              child: Text(
                'No active orders',
                style: GoogleFonts.urbanist(fontSize: 18),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ownerState.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = ownerState.orders[index];
                return Card(
                  child: ExpansionTile(
                    title: Text('Order #${order.orderId}'),
                    subtitle: Text(
                      'Status: ${order.status.toUpperCase()} \nTotal: ₹${order.totalAmount}',
                    ),
                    trailing: _buildStatusAction(order.status, order.id, ref),
                    children: order.items
                        .map(
                          (item) => ListTile(
                            title: Text(item.name),
                            subtitle: Text('Qty: ${item.quantity}'),
                            trailing: Text('₹${item.price}'),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
    );
  }

  Widget? _buildStatusAction(String status, String orderId, WidgetRef ref) {
    if (status == 'paid' || status == 'pending') {
      return ElevatedButton(
        onPressed: () {
          ref
              .read(ownerProvider.notifier)
              .updateOrderStatus(orderId, 'preparing');
        },
        child: const Text('Start Cooking'),
      );
    } else if (status == 'preparing') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        onPressed: () {
          ref.read(ownerProvider.notifier).updateOrderStatus(orderId, 'ready');
        },
        child: const Text('Mark Ready', style: TextStyle(color: Colors.white)),
      );
    } else if (status == 'ready') {
      return const Text(
        'Wait Pickup',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      );
    }
    return null;
  }
}
