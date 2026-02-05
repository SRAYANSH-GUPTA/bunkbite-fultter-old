import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_nav_bar.dart';
import '../providers/tab_provider.dart';
import '../providers/canteen_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  final List<Widget> _screens = [
    const MenuScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh canteen status when app is resumed/opened
      ref.read(canteenProvider.notifier).fetchCanteens();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      extendBody: true, // Fixes white screen by extending body behind floating navbar
      body: IndexedStack(index: currentIndex, children: _screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Center(
        child: CustomNavBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            ref.read(selectedTabProvider.notifier).state = index;
          },
        ),
      ),
    );
  }
}
