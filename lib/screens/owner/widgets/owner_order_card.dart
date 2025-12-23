import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/order_model.dart';
import '../../../providers/owner_provider.dart';

class OwnerOrderCard extends ConsumerWidget {
  final OrderModel order;

  const OwnerOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Status Logic
    // Pending -> Start -> Preparing
    // Preparing -> Mark Ready -> Ready
    // Ready -> Complete -> Completed

    final status = order.status.toLowerCase();

    Color statusColor;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'preparing':
        statusColor = Colors.blue;
        statusText = 'Preparing';
        break;
      case 'ready':
        statusColor = Colors.green;
        statusText = 'Ready';
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.black;
        statusText = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D9E9E9E),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID + Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.id.substring(order.id.length - 6).toUpperCase()}',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                DateFormat(
                  'hh:mm a',
                ).format(DateTime.parse(order.createdAt).toLocal()),
                style: GoogleFonts.urbanist(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 20),

          // Items List
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.urbanist(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 20),

          // Payment Info
          if (order.paymentId != null || order.paymentStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Status',
                        style: GoogleFonts.urbanist(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: order.paymentStatus == 'completed'
                              ? const Color(0x1A4CAF50)
                              : const Color(0x1AFF9800),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: order.paymentStatus == 'completed'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        child: Text(
                          order.paymentStatus.toUpperCase(),
                          style: GoogleFonts.urbanist(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: order.paymentStatus == 'completed'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (order.paymentId != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Payment ID',
                          style: GoogleFonts.urbanist(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.paymentId!.length > 15
                              ? '...${order.paymentId!.substring(order.paymentId!.length - 12)}'
                              : order.paymentId!,
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          const Divider(height: 20),

          // Footer: Total + Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Bill',
                    style: GoogleFonts.urbanist(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFFF62F56),
                    ),
                  ),
                ],
              ),

              // Action Button
              // Action Button
              if (status == 'preparing' || status == 'ready')
                ElevatedButton(
                  onPressed: () {
                    String nextStatus = status;
                    if (status == 'preparing') {
                      nextStatus = 'ready';
                    } else if (status == 'ready')
                      nextStatus = 'completed';

                    if (nextStatus != status) {
                      ref
                          .read(ownerProvider.notifier)
                          .updateOrderStatus(order.id, nextStatus);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    status == 'preparing'
                        ? 'Mark Ready'
                        : 'Complete', // status == ready
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
