import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/owner_provider.dart';
import '../widgets/order_details_dialog.dart';

class QRScannerView extends ConsumerStatefulWidget {
  final Function(bool)? onProcessingChanged;

  const QRScannerView({super.key, this.onProcessingChanged});

  @override
  ConsumerState<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends ConsumerState<QRScannerView> {
  bool _isProcessing = false;
  bool _isActive = true; // Track if scanner is still active
  final MobileScannerController _controller = MobileScannerController();

  Future<void> _handleScan(BarcodeCapture capture) async {
    // Check if scanner is still active first
    if (!_isActive || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    widget.onProcessingChanged?.call(true); // Notify parent
    _controller.stop();

    try {
      // QR code contains JSON: {"orderId":"ORD-XXX","timestamp":123,"signature":"..."}
      String? orderId;

      try {
        // Try parsing as JSON first
        final qrData = jsonDecode(code);
        orderId = qrData['orderId'];
      } catch (e) {
        // If not JSON, try other formats
        if (code.startsWith('ORDER:')) {
          orderId = code.substring(6);
        } else {
          orderId = code; // Assume it's the order ID directly
        }
      }

      if (orderId == null || orderId.isEmpty) {
        if (mounted && _isActive) {
          _showErrorDialog('Invalid QR code format');
        }
        return;
      }

      // First verify the QR code
      final isValid = await ref.read(ownerProvider.notifier).verifyQr(code);

      if (!isValid) {
        if (mounted && _isActive) {
          _showErrorDialog('Invalid or expired QR code');
        }
        return;
      }

      // Fetch order details using the extracted orderId
      final order = await ref
          .read(ownerProvider.notifier)
          .fetchOrderById(orderId);

      if (order == null) {
        if (mounted && _isActive) {
          _showErrorDialog('Could not fetch order details');
        }
        return;
      }

      // Check if order is already completed/picked up
      if (order.status.toLowerCase() == 'completed') {
        if (mounted && _isActive) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Icon(
                Icons.check_circle_outline,
                color: Colors.grey,
                size: 50,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Order Already Picked Up',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order #${order.orderId}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog

                    // Navigate back to scanner if not there
                    if (!_isActive) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const QRScannerView(),
                        ),
                      );
                    } else {
                      // Still on scanner, just restart
                      _controller.start();
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show order details dialog for orders that can be picked up
      if (mounted && _isActive) {
        bool pickupConfirmed = false; // Track if user confirmed pickup

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => OrderDetailsDialog(
            order: order,
            onConfirmPickup: () async {
              pickupConfirmed = true; // Mark that pickup was confirmed
              Navigator.pop(ctx); // Close order details dialog

              // Explicitly ensure processing state is active
              if (mounted && _isActive) {
                setState(() => _isProcessing = true);
                widget.onProcessingChanged?.call(true);
                // Small delay to ensure UI updates before API call
                await Future.delayed(const Duration(milliseconds: 100));
              }

              // Use the original QR code for pickup verification
              final success = await ref
                  .read(ownerProvider.notifier)
                  .completePickup(code);

              if (mounted && _isActive) {
                // Reset processing state before showing dialogs
                setState(() => _isProcessing = false);
                widget.onProcessingChanged?.call(false);

                if (success) {
                  _showSuccessDialog();
                } else {
                  _showErrorDialog('Failed to complete pickup');
                }
              }
            },
          ),
        ).then((_) {
          // Only restart scanner if dialog was dismissed WITHOUT confirming pickup
          if (mounted && _isActive && !pickupConfirmed) {
            setState(() => _isProcessing = false);
            widget.onProcessingChanged?.call(false);
            _controller.start();
          }
        });
      }
    } catch (e) {
      if (mounted && _isActive) {
        _showErrorDialog('Error processing QR code: ${e.toString()}');
      }
    } finally {
      if (mounted && _isActive) {
        setState(() => _isProcessing = false);
        widget.onProcessingChanged?.call(false); // Notify parent
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Text(
          'Order Picked Up Successfully!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog

              // Navigate back to scanner if not there
              if (!_isActive) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const QRScannerView()),
                );
              } else {
                // Still on scanner, just restart
                _controller.start();
              }
            },
            child: const Text('Scan Next'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Icon(Icons.error, color: Colors.red, size: 50),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog

              // Navigate back to scanner if not there
              if (!_isActive) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const QRScannerView()),
                );
              } else {
                // Still on scanner, just restart
                _controller.start();
              }
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void deactivate() {
    // Called when widget is removed from tree (e.g., navigation)
    _isActive = false;
    _controller.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _isActive = false; // Prevent any pending dialogs from showing
    _controller.stop(); // Stop scanning
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Scan Order QR",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleScan),
          // Overlay
          Container(decoration: BoxDecoration(color: const Color(0x80000000))),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
                color: const Color(0x1AFFFFFF), // Cutout effect simulated
              ),
              child: const Center(
                child: Text(
                  "Align QR Code",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          // Processing overlay - blocks touches and shows loading
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Processing QR Code...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
