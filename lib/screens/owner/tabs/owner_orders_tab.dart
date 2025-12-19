import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/owner_provider.dart';
import '../widgets/owner_order_card.dart';

class OwnerOrdersTab extends ConsumerStatefulWidget {
  const OwnerOrdersTab({super.key});

  @override
  ConsumerState<OwnerOrdersTab> createState() => _OwnerOrdersTabState();
}

class _OwnerOrdersTabState extends ConsumerState<OwnerOrdersTab> {
  String _selectedFilter = 'All'; // All, Pending, Preparing, Ready, Completed

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

    final filteredOrders = ownerState.orders.where((order) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Pending')
        return order.status == 'pending'; // or 'new'
      if (_selectedFilter == 'Preparing') return order.status == 'preparing';
      if (_selectedFilter == 'Ready') return order.status == 'ready';
      if (_selectedFilter == 'Completed') return order.status == 'completed';
      return true;
    }).toList();

    // Sort: Pending first, then by date
    filteredOrders.sort((a, b) {
      // Custom priority if needed
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Orders',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(ownerProvider.notifier).fetchMyCanteens();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Preparing'),
                const SizedBox(width: 8),
                _buildFilterChip('Ready'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed'),
              ],
            ),
          ),

          // Order List
          Expanded(
            child: ownerState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No ${_selectedFilter == 'All' ? '' : _selectedFilter} Orders',
                          style: GoogleFonts.urbanist(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return OwnerOrderCard(order: filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0x1AF62F56),
      labelStyle: GoogleFonts.urbanist(
        color: isSelected ? const Color(0xFFF62F56) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFFF62F56) : Colors.grey[300]!,
        ),
      ),
      showCheckmark: false,
    );
  }
}
