import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/home_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/search_provider.dart';

class FuocoBottomNav extends ConsumerWidget {
  final int currentIndex;
  
  const FuocoBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(searchBarVisibilityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BottomAppBar(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildNavItem(context, Icons.home_outlined, currentIndex == 0, () {
                    if (currentIndex != 0) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    }
                  }),
                  const SizedBox(width: 20),
                  _buildNavItem(context, Icons.search_rounded, isSearching && currentIndex == 0, () {
                    if (currentIndex != 0) {
                      ref.read(searchBarVisibilityProvider.notifier).show();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    } else {
                      ref.read(searchBarVisibilityProvider.notifier).toggle();
                    }
                  }),
                ],
              ),
              Row(
                children: [
                  _buildNavItem(context, Icons.article_outlined, currentIndex == 2, () {
                    if (currentIndex != 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrdersScreen()),
                      );
                    }
                  }),
                  const SizedBox(width: 20),
                  _buildNavItem(context, Icons.person_outline, currentIndex == 1, () {
                    if (currentIndex != 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    }
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFED145B).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: isSelected 
              ? const Color(0xFFED145B) 
              : (isDark ? Colors.grey.shade400 : Colors.grey),
          size: 26,
        ),
      ),
    );
  }
}

class FuocoFAB extends StatelessWidget {
  const FuocoFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      ),
      backgroundColor: const Color(0xFFED145B),
      shape: CircleBorder(
        side: BorderSide(
          color: isDark ? const Color(0xFF121212) : Colors.white, 
          width: 4,
        ),
      ),
      elevation: 4,
      child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 28),
    );
  }
}
