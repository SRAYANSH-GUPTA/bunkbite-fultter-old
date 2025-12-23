import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/owner_provider.dart';
import '../sheets/item_sheet.dart';
import '../sheets/owner_canteen_selector_sheet.dart';
import '../sheets/quick_quantity_sheet.dart';

class OwnerMenuTab extends ConsumerStatefulWidget {
  const OwnerMenuTab({super.key});

  @override
  ConsumerState<OwnerMenuTab> createState() => _OwnerMenuTabState();
}

class _OwnerMenuTabState extends ConsumerState<OwnerMenuTab> {
  @override
  void initState() {
    super.initState();
    // Fetch menu when tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedCanteen = ref.read(ownerProvider).selectedCanteen;
      if (selectedCanteen != null) {
        ref.read(ownerProvider.notifier).fetchCanteenMenu(selectedCanteen.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ownerState = ref.watch(ownerProvider);
    final selectedCanteen = ownerState.selectedCanteen;

    // Listener to re-fetch if selected canteen changes
    ref.listen(ownerProvider, (prev, next) {
      if (prev?.selectedCanteen?.id != next.selectedCanteen?.id &&
          next.selectedCanteen != null) {
        ref
            .read(ownerProvider.notifier)
            .fetchCanteenMenu(next.selectedCanteen!.id);
      }
    });

    if (selectedCanteen == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No Canteen Selected',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const OwnerCanteenSelectorSheet(),
                  );
                },
                child: const Text('Select Canteen'),
              ),
            ],
          ),
        ),
      );
    }

    final menuItems = ownerState.menu;
    final totalItems = menuItems.length;
    final outOfStock = menuItems.where((i) => i.availableQuantity == 0).length;
    final available = totalItems - outOfStock;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedCanteen.name,
                              style: GoogleFonts.urbanist(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              selectedCanteen.place,
                              style: GoogleFonts.urbanist(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                const OwnerCanteenSelectorSheet(),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Change'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFF62F56),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    children: [
                      _buildStatBadge(
                        'Total Items',
                        totalItems.toString(),
                        Colors.blue,
                        Colors.blue[50]!,
                      ),
                      const SizedBox(width: 10),
                      _buildStatBadge(
                        'Available',
                        available.toString(),
                        Colors.green,
                        Colors.green[50]!,
                      ),
                      const SizedBox(width: 10),
                      _buildStatBadge(
                        'Out of Stock',
                        outOfStock.toString(),
                        Colors.red,
                        Colors.red[50]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // List
            Expanded(
              child: ownerState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : menuItems.isEmpty
                  ? Center(
                      child: Text(
                        'No items in inventory.\nAdd your first item!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(ownerProvider.notifier)
                            .fetchCanteenMenu(selectedCanteen.id);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: menuItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = menuItems[index];
                          final isOutOfStock = item.availableQuantity == 0;

                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Item?'),
                                  content: Text(
                                    'Are you sure you want to delete ${item.name}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) {
                              ref
                                  .read(ownerProvider.notifier)
                                  .deleteMenuItem(selectedCanteen.id, item.id);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ItemSheet(
                                    item: item,
                                    canteenId: selectedCanteen.id,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0x0D9E9E9E),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Placeholder Image
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                        image: item.image != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  item.image!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: item.image == null
                                          ? const Icon(
                                              Icons.fastfood,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: GoogleFonts.urbanist(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            '₹${item.price}',
                                            style: GoogleFonts.urbanist(
                                              color: const Color(0xFFF62F56),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Open Quick Quantity Sheet
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => QuickQuantitySheet(
                                            item: item,
                                            canteenId: selectedCanteen.id,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOutOfStock
                                              ? const Color(0x1AF44336)
                                              : const Color(0x1A4CAF50),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isOutOfStock
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 14,
                                              color: isOutOfStock
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${item.availableQuantity}',
                                              style: GoogleFonts.urbanist(
                                                fontWeight: FontWeight.bold,
                                                color: isOutOfStock
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ItemSheet(canteenId: selectedCanteen.id),
          );
        },
        backgroundColor: const Color(0xFFF62F56),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatBadge(
    String label,
    String value,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.urbanist(color: color, fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.urbanist(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
