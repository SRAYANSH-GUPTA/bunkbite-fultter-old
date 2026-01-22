import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5, left: 24, right: 24),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Shrink to fit items
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.restaurant_menu, // Fork and Menu icon
              label: 'Menu',
              isSelected: selectedIndex == 0,
            ),
            const SizedBox(width: 8),
            _buildNavItem(
              index: 1,
              icon: Icons.shopping_cart,
              label: 'Orders',
              isSelected: selectedIndex == 1,
            ),
            const SizedBox(width: 8),
            _buildNavItem(
              index: 2,
              icon: Icons.person,
              label: 'Profile',
              isSelected: selectedIndex == 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onDestinationSelected(index),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 500,
        ), // Slightly longer for bounce
        curve: Curves.elasticOut, // Bounce effect
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B7D3B) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: const Color(0xFF06BD52), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 24,
            ),
            // Animate text width/appearance
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: isSelected
                    ? null
                    : 0, // Collapse width when not selected
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
