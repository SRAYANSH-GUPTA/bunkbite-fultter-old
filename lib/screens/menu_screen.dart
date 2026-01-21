import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/canteen_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/menu_item_card.dart';
import 'cart_screen.dart';
import 'search_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Meals', 'Snacks', 'Drinks'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(canteenProvider.notifier).fetchCanteens();
    });
  }

  void _showCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canteenState = ref.watch(canteenProvider);
    final cartState = ref.watch(cartProvider);

    // Filter menu based on category only
    final filteredMenu = canteenState.menu.where((item) {
      // Category filter (basic implementation - you may need to add category field to MenuItem)
      if (_selectedCategory != 'All') {
        // This is a simple categorization based on item names
        // You should ideally have a category field in your MenuItem model
        final itemName = item.name.toLowerCase();
        switch (_selectedCategory) {
          case 'Meals':
            if (!itemName.contains('burger') &&
                !itemName.contains('rice') &&
                !itemName.contains('noodles') &&
                !itemName.contains('samose'))
              return false;
            break;
          case 'Snacks':
            if (!itemName.contains('samosa') &&
                !itemName.contains('pakora') &&
                !itemName.contains('fries'))
              return false;
            break;
          case 'Drinks':
            if (!itemName.contains('tea') &&
                !itemName.contains('coffee') &&
                !itemName.contains('juice') &&
                !itemName.contains('shake'))
              return false;
            break;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: Color(0xFF0B7D3B),
            ),
            const SizedBox(width: 4),
            if (canteenState.selectedCanteen != null)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            // Handle
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Title
                            Text(
                              'Select Canteen',
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // List
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(24),
                                itemCount: canteenState.canteens.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final canteen = canteenState.canteens[index];
                                  final isSelected =
                                      canteen.id ==
                                      canteenState.selectedCanteen?.id;
                                  return InkWell(
                                    onTap: () {
                                      ref
                                          .read(canteenProvider.notifier)
                                          .selectCanteen(canteen);
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0B7D3B)
                                              : Colors.grey[200]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        color: isSelected
                                            ? const Color(0xFFE5F5ED)
                                            : Colors.white,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              canteen.name,
                                              style: GoogleFonts.urbanist(
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (!canteen.isCurrentlyOpen)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.pink[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Closed',
                                                style: GoogleFonts.urbanist(
                                                  color: Colors.pink,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          if (canteen.isCurrentlyOpen &&
                                              isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF0B7D3B),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          canteenState.selectedCanteen!.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 20),
                    ],
                  ),
                ),
              )
            else
              Text(
                'Select Canteen',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black,
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
                      color: Color(0xFF0B7D3B),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartState.totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(canteenProvider.notifier).fetchCanteens();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Hungry?',
                    style: GoogleFonts.urbanist(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Beat the rush.',
                    style: GoogleFonts.urbanist(
                      fontSize: 24,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  GestureDetector(
                    onTap: () {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Search',
                        barrierColor: Colors.black54,
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, anim1, anim2) =>
                            const SearchScreen(),
                        transitionBuilder: (context, anim1, anim2, child) {
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, -1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: anim1,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                            child: child,
                          );
                        },
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 22,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Search for ',
                                style: GoogleFonts.urbanist(
                                  color: Colors.grey[500],
                                  fontSize: 15,
                                ),
                              ),
                              IgnorePointer(
                                child: DefaultTextStyle(
                                  style: GoogleFonts.urbanist(
                                    color: Colors.grey[500],
                                    fontSize: 15,
                                  ),
                                  child: AnimatedTextKit(
                                    animatedTexts: [
                                      TypewriterAnimatedText(
                                        'food...',
                                        speed: const Duration(
                                          milliseconds: 100,
                                        ),
                                      ),
                                      TypewriterAnimatedText(
                                        '"Pizza"',
                                        speed: const Duration(
                                          milliseconds: 100,
                                        ),
                                      ),
                                      TypewriterAnimatedText(
                                        '"Burger"',
                                        speed: const Duration(
                                          milliseconds: 100,
                                        ),
                                      ),
                                    ],
                                    repeatForever: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Tabs
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 16),

            // Menu Grid
            Expanded(
              child: canteenState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : canteenState.canteens.isEmpty
                  ? const Center(child: Text("No Canteens Available"))
                  : filteredMenu.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No menu items available",
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: filteredMenu.length,
                      itemBuilder: (context, index) {
                        final item = filteredMenu[index];
                        final isOpen =
                            canteenState.selectedCanteen?.isCurrentlyOpen ??
                            true;

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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
