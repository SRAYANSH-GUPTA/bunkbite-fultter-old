import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'camera/qr_scanner_view.dart';
import 'sheets/owner_canteen_selector_sheet.dart';
import 'tabs/owner_menu_tab.dart';
import 'tabs/owner_orders_tab.dart';
import 'tabs/owner_profile_view.dart';
import '../../providers/owner_provider.dart';

class OwnerMainView extends ConsumerStatefulWidget {
  const OwnerMainView({super.key});

  @override
  ConsumerState<OwnerMainView> createState() => _OwnerMainViewState();
}

class _OwnerMainViewState extends ConsumerState<OwnerMainView> {
  int _currentIndex = 1; // Default to Orders Tab
  bool _isScannerProcessing = false; // Track scanner processing state

  Widget _getCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const OwnerMenuTab();
      case 1:
        return const OwnerOrdersTab();
      case 2:
        return const OwnerProfileView();
      case 3:
        return QRScannerView(
          onProcessingChanged: (isProcessing) {
            if (mounted) {
              setState(() => _isScannerProcessing = isProcessing);
            }
          },
        );
      default:
        return const OwnerOrdersTab();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCanteen();
    });
  }

  void _checkCanteen() {
    final ownerState = ref.read(ownerProvider);
    // If not loading and no canteen selected, show selector
    if (!ownerState.isLoading && ownerState.selectedCanteen == null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const OwnerCanteenSelectorSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider to handle loading states or changes if needed
    ref.listen(ownerProvider, (previous, next) {
      if (previous?.selectedCanteen != null && next.selectedCanteen == null) {
        // Handle case where canteen might be deleted or deselected?
        // For now, re-trigger check
        _checkCanteen();
      }
    });

    return Scaffold(
      body: _getCurrentTab(), // Direct widget switching instead of IndexedStack
      bottomNavigationBar: IgnorePointer(
        ignoring: _isScannerProcessing, // Disable navbar during processing
        child: Opacity(
          opacity: _isScannerProcessing ? 0.5 : 1.0, // Visual feedback
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              // Only allow navigation if not processing
              if (!_isScannerProcessing) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            backgroundColor: Colors.white,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.restaurant), // fork.knife equivalent
                label: 'Inventory',
              ),
              NavigationDestination(
                icon: Icon(Icons.list_alt), // list.clipboard equivalent
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline), // person equivalent
                label: 'Profile',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.qr_code_scanner,
                ), // qrcode.viewfinder equivalent
                label: 'Scan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
