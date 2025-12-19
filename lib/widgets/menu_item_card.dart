import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/menu_item_model.dart';
import '../providers/cart_provider.dart';
import '../screens/login_sheet.dart';

class MenuItemCard extends ConsumerWidget {
  final MenuItem item;
  final String canteenId;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.canteenId,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final quantity = cart.items[item.id]?.quantity ?? 0;
    final isOutOfStock = item.availableQuantity == 0;
    final isMaxQuantity = quantity >= item.availableQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isOutOfStock ? null : () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image Section
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    image: item.image != null && item.image!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.image == null || item.image!.isEmpty
                      ? Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey[400],
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // Content Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Item Name
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Availability & Price Row
                      Row(
                        children: [
                          // Availability Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? const Color(0x1AF44336)
                                  : const Color(0x1A4CAF50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOutOfStock
                                      ? Icons.close
                                      : Icons.check_circle,
                                  size: 12,
                                  color: isOutOfStock
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOutOfStock
                                      ? 'Out of stock'
                                      : '${item.availableQuantity} left',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isOutOfStock
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Price
                          Text(
                            '₹${item.price.toInt()}',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFFF62F56),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Action Button Section
                if (isOutOfStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'N/A',
                      style: GoogleFonts.urbanist(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                else if (quantity == 0)
                  Material(
                    color: const Color(0xFFF62F56),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Auth Check
                        final auth = ref.read(authProvider);
                        if (!auth.isAuthenticated) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const LoginSheet(),
                          );
                          return;
                        }
                        ref
                            .read(cartProvider.notifier)
                            .addItem(item, canteenId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          'ADD',
                          style: GoogleFonts.urbanist(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0x1AF62F56),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF62F56),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Minus Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            onTap: () {
                              ref.read(cartProvider.notifier).removeItem(item);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.remove,
                                size: 18,
                                color: Color(0xFFF62F56),
                              ),
                            ),
                          ),
                        ),

                        // Quantity
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$quantity',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFFF62F56),
                            ),
                          ),
                        ),

                        // Plus Button - Disabled when max quantity reached
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            onTap: isMaxQuantity
                                ? null
                                : () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .addItem(item, canteenId);
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: isMaxQuantity
                                    ? Colors.grey
                                    : const Color(0xFFF62F56),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
