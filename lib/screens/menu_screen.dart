import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
              floating: false,
              snap: false,
              expandedHeight: 120, // Increased for Menu title
              backgroundColor: Colors.white,
              elevation: 0,

              // Title that shows when collapsed
              title: Text(
                'Menu',
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Menu Title (large when expanded)
                      Text(
                        'Menu',
                        style: GoogleFonts.urbanist(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pinned bottom section with canteen selector AND search bar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(
                  140,
                ), // Adjusted for better spacing
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      // Canteen Selector - Aligned with search bar
                      Container(
                        height: 52, // Same height as search bar for consistency
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF62F56),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x0DF62F56),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: canteenState.isLoading
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFF62F56),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Loading canteens...',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              )
                            : canteenState.canteens.isEmpty
                            ? Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'No canteens available',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              )
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: canteenState.selectedCanteen?.id,
                                  hint: Row(
                                    children: [
                                      const Icon(
                                        Icons.store_outlined,
                                        size: 20,
                                        color: Color(0xFFF62F56),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Select Canteen',
                                        style: GoogleFonts.urbanist(
                                          color: Colors.grey[600],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color(0xFFF62F56),
                                    size: 24,
                                  ),
                                  style: GoogleFonts.urbanist(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: canteenState.canteens.map((canteen) {
                                    return DropdownMenuItem(
                                      value: canteen.id,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.store,
                                            size: 20,
                                            color: Color(0xFFF62F56),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              canteen.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.urbanist(
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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

                      const SizedBox(height: 12), // Consistent spacing
                      // Search Bar - Matching height and style
                      Container(
                        height: 52, // Same height as canteen selector
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: GoogleFonts.urbanist(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search for food...',
                            hintStyle: GoogleFonts.urbanist(
                              color: Colors.grey[500],
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 22,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredMenu[index];
                      final isOpen =
                          canteenState.selectedCanteen?.isCurrentlyOpen ?? true;

                      return Opacity(
                        opacity: isOpen ? 1.0 : 0.6,
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
