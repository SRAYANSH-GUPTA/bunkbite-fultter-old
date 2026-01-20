import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/canteen_provider.dart';

class QuickQuantitySheet extends ConsumerStatefulWidget {
  final MenuItem item;
  final String canteenId;

  const QuickQuantitySheet({
    super.key,
    required this.item,
    required this.canteenId,
  });

  @override
  ConsumerState<QuickQuantitySheet> createState() => _QuickQuantitySheetState();
}

class _QuickQuantitySheetState extends ConsumerState<QuickQuantitySheet> {
  late int _quantity;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.availableQuantity;
  }

  void _increment() {
    setState(() {
      _quantity++;
    });
  }

  void _decrement() {
    if (_quantity > 0) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _save() async {
    if (_quantity == widget.item.availableQuantity) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    // Prepare update data
    // existing item data + new qty
    final itemData = widget.item.toJson();
    itemData['availableQuantity'] = _quantity;

    // Use updateItem from provider
    // Note: updateItem expects the full object logic or partial?
    // Provider code (step 179) calls put /menu/$id with data.
    // If backend partial update is supported, we can send just { availableQuantity: _qty }.
    // Let's safe side send full known props or just qty if backend allows.
    // Given updateItem signature takes generic map, let's try just qty if that worked before,
    // but in ItemSheet we sent everything.
    // Let's send everything to be safe or just minimal.
    // The safest is minimal if backend supports PATCH, but it uses PUT.
    // If PUT usually requires full object.
    // Let's assume we need to send at least name/price/qty.
    // We already have widget.item.toJson(), so that's good.

    final success = await ref
        .read(canteenProvider.notifier)
        .updateItem(widget.item.id, itemData);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update quantity')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Update Stock',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.item.name,
            style: GoogleFonts.urbanist(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _decrement,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 30),
              Text(
                '$_quantity',
                style: GoogleFonts.urbanist(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 30),
              IconButton.filledTonal(
                onPressed: _increment,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B7D3B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
