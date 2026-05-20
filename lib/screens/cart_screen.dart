import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/language_provider.dart';
import 'delivery_screen.dart';
import 'home_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  String? _couponError;

  List<FoodItem> _getDynamicSuggestedExtras(List<CartItem> cartItems) {
    final suggestions = <FoodItem>[];
    
    final hasRice = cartItems.any((cartItem) => cartItem.item.category.toLowerCase() == 'rice');
    final hasMeatboxOrBurgerOrCombo = cartItems.any((cartItem) => 
      ['meatbox', 'burger', 'combo', 'appetizers'].contains(cartItem.item.category.toLowerCase())
    );
    final hasPizza = cartItems.any((cartItem) => cartItem.item.category.toLowerCase() == 'pizza');

    // 1. Extra Rice - only for Rice orders
    if (hasRice) {
      suggestions.add(
        FoodItem(
          id: 'extra_2',
          name: 'Extra Rice',
          description: 'Steamed premium basmati rice',
          price: 60.0,
          imageUrl: 'assets/images/Extra/Extra Rice.jpg',
          category: 'Extra',
        ),
      );
    }

    // 2. BBQ Sauce - for Meatbox, Burger, Combo, Appetizers, Pizza
    if (hasMeatboxOrBurgerOrCombo || hasPizza || suggestions.isEmpty) {
      suggestions.add(
        FoodItem(
          id: 'extra_1',
          name: 'BBQ Sauce',
          description: 'Rich, smoky BBQ sauce',
          price: 30.0,
          imageUrl: 'assets/images/Extra/BBQ Sauce.jpeg',
          category: 'Extra',
        ),
      );
    }

    // 3. Honey Mustard - for Meatbox, Burger, Combo, Appetizers
    if (hasMeatboxOrBurgerOrCombo || suggestions.isEmpty) {
      suggestions.add(
        FoodItem(
          id: 'extra_3',
          name: 'Honey Mustard',
          description: 'Sweet & tangy dip',
          price: 35.0,
          imageUrl: 'assets/images/Extra/honey mustard.jpeg',
          category: 'Extra',
        ),
      );
    }

    return suggestions;
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartMap = ref.watch(cartProvider);
    final cartItems = cartMap.values.toList();
    final totalPrice = ref.watch(cartProvider.notifier).totalPrice;
    final appliedCoupon = ref.watch(couponProvider);

    double discount = 0.0;
    if (appliedCoupon != null) {
      if (appliedCoupon.discountPercent > 0) {
        discount = totalPrice * appliedCoupon.discountPercent;
      } else {
        discount = appliedCoupon.discountAmount;
      }
    }
    final grandTotal = totalPrice - discount;

    final dynamicSuggestedExtras = _getDynamicSuggestedExtras(cartItems);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Clean Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white70 : Colors.black87, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    ref.tr('my_cart'),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF2D3142),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                    onPressed: () {
                      ref.read(cartProvider.notifier).clearCart();
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ref.tr('cart_empty'),
                            style: const TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                              (route) => false,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFED145B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              ref.tr('add_items'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Scrollable list items
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cartItems.length,
                                  itemBuilder: (context, index) {
                                    final cartItem = cartItems[index];
                                    final item = cartItem.item;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.grey.shade100,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.asset(
                                              item.imageUrl,
                                              width: 75,
                                              height: 75,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.fastfood,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    color: Color(0xFF2D3142),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '৳${item.price.toInt()}',
                                                  style: const TextStyle(
                                                    color: Color(0xFFED145B),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Modern Pill Quantity Selector
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F2F6),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => ref
                                                      .read(cartProvider.notifier)
                                                      .decrementQuantity(item.id),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).cardColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.remove, size: 12, color: Color(0xFF2D3142)),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  child: Text(
                                                    cartItem.quantity.toString(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF2D3142),
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => ref
                                                      .read(cartProvider.notifier)
                                                      .incrementQuantity(item.id),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFFED145B),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.add, size: 12, color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                if (dynamicSuggestedExtras.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      ref.tr('suggested_extras'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF2D3142),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 175,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: dynamicSuggestedExtras.length,
                                      itemBuilder: (context, index) {
                                        final extraItem = dynamicSuggestedExtras[index];
                                        final isInCart = cartMap.containsKey(extraItem.id);
                                        return Container(
                                          width: 145,
                                          margin: const EdgeInsets.only(right: 14, bottom: 8, left: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.grey.shade100,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                    child: Image.asset(
                                                      extraItem.imageUrl,
                                                      height: 90,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        height: 90,
                                                        color: Colors.grey[100],
                                                        child: const Icon(Icons.fastfood, color: Colors.grey),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: 8,
                                                    top: 8,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        ref.read(cartProvider.notifier).addItem(extraItem);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('${extraItem.name} added to cart!'),
                                                            duration: const Duration(seconds: 1),
                                                            backgroundColor: const Color(0xFFED145B),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFFED145B),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      extraItem.name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 13,
                                                        color: Color(0xFF2D3142),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          '৳${extraItem.price.toInt()}',
                                                          style: const TextStyle(
                                                            color: Color(0xFFED145B),
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        if (isInCart)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFED145B).withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              '${cartMap[extraItem.id]?.quantity ?? 0}x',
                                                              style: const TextStyle(
                                                                color: Color(0xFFED145B),
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        // Sticky Bottom Panel
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Coupon Input Section
                              if (appliedCoupon == null) ...[
                                Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200, width: 1.0),
                                  ),
                                  padding: const EdgeInsets.only(left: 14, right: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.confirmation_number_outlined, color: Color(0xFFED145B), size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _couponController,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                                          decoration: InputDecoration(
                                            hintText: ref.tr('enter_coupon'),
                                            errorText: _couponError != null ? ref.tr('invalid') : null,
                                            errorStyle: const TextStyle(height: 0),
                                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 38,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            final code = _couponController.text.trim();
                                            if (code.isEmpty) return;
                                            final success = ref.read(couponProvider.notifier).applyCoupon(code, totalPrice);
                                            setState(() {
                                              if (success) {
                                                _couponError = null;
                                                _couponController.clear();
                                              } else {
                                                _couponError = 'Invalid';
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFED145B),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(ref.tr('apply'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      ref.tr('try_coupon'),
                                      style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFA5D6A7), width: 1.0),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          ref.tr('promo_applied').replaceAll('{0}', appliedCoupon.code).replaceAll('{1}', discount.toInt().toString()),
                                          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.green, fontSize: 13),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(couponProvider.notifier).clearCoupon();
                                        },
                                        child: Text(ref.tr('remove'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              
                              // Price Breakdown List
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(ref.tr('subtotal'), style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                                  Text('৳${totalPrice.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                                ],
                              ),
                              if (appliedCoupon != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(ref.tr('discount'), style: const TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w500)),
                                    Text('-৳${discount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.redAccent)),
                                  ],
                                ),
                              ],
                              const Divider(height: 24, thickness: 1.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(ref.tr('total_amount'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
                                  Text('৳${grandTotal.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFED145B))),
                                ],
                              ),
                              
                              const SizedBox(height: 18),
                              
                              // Checkout Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFED145B), Color(0xFFF93B7D)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFED145B).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const DeliveryScreen()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: Text(
                                      ref.tr('proceed_delivery'),
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
