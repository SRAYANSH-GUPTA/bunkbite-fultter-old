import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/canteen_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/menu_item_card.dart';
import 'login_sheet.dart';
import 'cart_sheet.dart'; // Will implement next

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch canteens on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(canteenProvider.notifier).fetchCanteens();
    });
  }

  void _showLogin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LoginSheet(),
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartSheet(),
    );
  }

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canteenState = ref.watch(canteenProvider);
    final authState = ref.watch(authProvider);
    final cartState = ref.watch(cartProvider);

    // Filter menu based on search
    final filteredMenu = canteenState.menu.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light gray background
      // Removed FloatingActionButton as requested
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(canteenProvider.notifier).fetchCanteens();
        },
        child: CustomScrollView(
          slivers: [
            // Header and Banner
            SliverAppBar(
              pinned: true,
              expandedHeight: 240, // Slightly taller for better spacing
              backgroundColor: Colors.white,

              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Greeting and Canteen Selector in a Column for better spacing
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good Morning,',
                                  style: GoogleFonts.urbanist(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  authState.user?.name ?? 'Guest',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Canteen Selector - Moved down or adjusted?
                          // Let's keep it here but ensure it doesn't overlap text?
                          // Actually user said overlap with Cart Icon (Top Right).
                          // If we move it down into the body, it won't overlap.
                          // But flexible space is best.
                          // Let's just give it explicit spacing.
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Canteen Selector (Full width or distinct row)
                      if (!canteenState.isLoading &&
                          canteenState.canteens.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded:
                                  true, // Full width to avoid layout issues
                              value: canteenState.selectedCanteen?.id,
                              hint: const Text('Select Canteen'),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFFF62F56),
                              ),
                              style: GoogleFonts.urbanist(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              items: canteenState.canteens.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                final selected = canteenState.canteens
                                    .firstWhere((c) => c.id == val);
                                ref
                                    .read(canteenProvider.notifier)
                                    .selectCanteen(selected);
                              },
                            ),
                          ),
                        ),

                      const SizedBox(height: 15),
                      // Search Bar
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search for food...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () => _showCart(context),
                    ),
                    if (cartState.totalItems > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF62F56),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cartState.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
              ],
            ),

            // Menu Content
            if (canteenState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (canteenState.canteens.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text("No Canteens Available")),
              )
            else ...[
              if (canteenState.selectedCanteen != null &&
                  !canteenState.selectedCanteen!.isCurrentlyOpen)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0x1AF44336),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.store_mall_directory,
                          size: 40,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'SORRY WE\'RE CLOSED',
                          style: GoogleFonts.urbanist(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'This canteen is currently not accepting orders. \nOpen: ${canteenState.selectedCanteen!.openingTime} - ${canteenState.selectedCanteen!.closingTime}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.urbanist(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),

              // Menu Content
              if (filteredMenu.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.restaurant_menu
                              : Icons.search_off,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isEmpty
                              ? "No menu items available"
                              : "No items match your search",
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_searchQuery.isEmpty)
                          Text(
                            "This canteen hasn't added any items yet",
                            style: GoogleFonts.urbanist(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredMenu[index]; // Use filteredMenu
                      final isOpen =
                          canteenState.selectedCanteen?.isCurrentlyOpen ?? true;

                      return Opacity(
                        opacity: isOpen ? 1.0 : 0.5,
                        child: AbsorbPointer(
                          absorbing: !isOpen,
                          child: MenuItemCard(
                            item: item,
                            canteenId: canteenState.selectedCanteen!.id,
                          ),
                        ),
                      );
                    }, childCount: filteredMenu.length),
                  ),
                ),
            ],

            const SliverPadding(
              padding: EdgeInsets.only(bottom: 80),
            ), // Space for FAB/Nav
          ],
        ),
      ),
    );
  }
}
