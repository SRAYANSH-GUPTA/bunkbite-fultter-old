import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../models/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final bool isReady = order.status == 'ready';
    final bool isCompleted = order.status == 'completed';

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (order.status == 'success' || order.paymentStatus == 'success')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x1A4CAF50),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Text(
                          'Order Placed Successfully',
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (order.paymentId != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Payment ID: ${order.paymentId}',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 30),

            // QR Code Section
            // Only show if NOT completed AND status is valid (not pending/failed)
            if (!isCompleted &&
                order.status != 'pending' &&
                order.status != 'cancelled')
              Column(
                children: [
                  Text(
                    isReady ? 'Ready for Pickup!' : 'Show this QR at Counter',
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x339E9E9E),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: order.qrCode != null && order.qrCode!.isNotEmpty
                        ? Image.memory(
                            base64Decode(
                              order.qrCode!.replaceFirst(
                                RegExp(r'data:image\/.*;base64,'),
                                '',
                              ),
                            ),
                            // Ensure clean base64 even if api sends data uri prefix
                            width: 200,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return QrImageView(
                                data: order.orderId,
                                version: QrVersions.auto,
                                size: 200.0,
                              );
                            },
                          )
                        : QrImageView(
                            data:
                                order.orderId, // Fallback to generating locals
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ID: ${order.orderId}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              )
            else if (isCompleted)
              Column(
                children: [
                  const Icon(
                    Icons.thumb_up,
                    size: 80,
                    color: Color(0xFFF62F56),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enjoy your meal!',
                    style: GoogleFonts.urbanist(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 40),

            // Item List
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Items',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...order.items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.urbanist(fontSize: 16),
                          ),
                        ),
                        Text(
                          '₹${item.price * item.quantity}',
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                ,

            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${order.totalAmount}',
                  style: GoogleFonts.urbanist(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF62F56),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
