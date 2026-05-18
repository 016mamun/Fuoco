import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../providers/favorites_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/fuoco_bottom_nav.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteItems = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Clean Header (My Order style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'My Favorites',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance and center the title
                ],
              ),
            ),

            Expanded(
              child: favoriteItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No favorites yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                              (route) => false,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA500),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Discover Food', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: favoriteItems.length,
                      itemBuilder: (context, index) {
                        final item = favoriteItems[index];
                        return GestureDetector(
                          onTap: () => _showFoodDetailsBottomSheet(context, ref, item),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.asset(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(favoritesProvider.notifier).toggleFavorite(item);
                                        },
                                        child: const Icon(Icons.favorite, color: Color(0xFFFFA500), size: 20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '৳${item.price.toInt()}',
                                        style: const TextStyle(
                                          color: Color(0xFFFFA500),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(cartProvider.notifier).addItem(item);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${item.name} added to cart!'),
                                              duration: const Duration(seconds: 1),
                                              backgroundColor: const Color(0xFFFFA500),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFFA500),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const FuocoBottomNav(currentIndex: 3),
      floatingActionButton: const FuocoFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showFoodDetailsBottomSheet(BuildContext context, WidgetRef ref, FoodItem item) {
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Cover Image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          child: Image.asset(
                            item.imageUrl,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 250,
                              color: const Color(0xFFFFF3E0),
                              child: const Icon(Icons.fastfood, size: 80, color: Color(0xFFFFA500)),
                            ),
                          ),
                        ),
                        // Close floating button
                        Positioned(
                          top: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white70,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.black87, size: 20),
                            ),
                          ),
                        ),
                        // Favorite Icon
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white70,
                              shape: BoxShape.circle,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                ref.read(favoritesProvider.notifier).toggleFavorite(item);
                                setModalState(() {});
                              },
                              child: const Icon(
                                Icons.favorite,
                                color: Color(0xFFFFA500),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge and Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFA500).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: Color(0xFFFFA500),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.rating.toString(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '(45+ reviews)',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Food Title
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Delivery detail / Sell info
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text('15 Mins Delivery', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(width: 16),
                              Icon(Icons.local_fire_department, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text('200+ Sold', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                          const Divider(height: 32),
                          
                          // Food Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description.isNotEmpty 
                                ? item.description 
                                : 'Treat yourself to our premium ${item.name}, masterfully prepared by our chefs using only the freshest ingredients and local spices. It is rich, delicious, and cooked to absolute perfection. Guaranteed to satisfy your cravings!',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const Divider(height: 32),
                          
                          // Quantity and Price row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Price', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '৳${(item.price * quantity).toInt()}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFA500),
                                    ),
                                  ),
                                ],
                              ),
                              // Counter
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (quantity > 1) {
                                        setModalState(() => quantity--);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.remove, size: 18, color: Colors.grey[700]),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      quantity.toString(),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() => quantity++);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.add, size: 18, color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Add to Cart Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                ref.read(cartProvider.notifier).addItemWithQuantity(item, quantity);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$quantity Pcs of ${item.name} added to cart!'),
                                    backgroundColor: const Color(0xFFFFA500),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA500),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 5,
                                shadowColor: const Color(0xFFFFA500).withOpacity(0.4),
                              ),
                              child: const Text(
                                'Add to Cart',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
