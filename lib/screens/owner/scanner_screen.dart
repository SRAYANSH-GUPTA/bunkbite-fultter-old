import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/owner_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _isProcessing = false;
  bool _isActive = true; // Track if scanner is still active

  @override
  void dispose() {
    _isActive = false; // Prevent any pending SnackBars from showing
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _isProcessing = true;
        final success = await ref
            .read(ownerProvider.notifier)
            .verifyQr(barcode.rawValue!);
        if (!mounted || !_isActive) return;

        if (success) {
          if (_isActive) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Order Verified!')));
            Navigator.pop(context);
          }
        } else {
          if (_isActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid QR or Verification Failed'),
              ),
            );
          }
          // Delay before processing again
          await Future.delayed(const Duration(seconds: 2));
          _isProcessing = false;
        }
        return; // Process only one
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(onDetect: _handleBarcode),
    );
  }
}
