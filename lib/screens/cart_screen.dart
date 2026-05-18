import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';
import 'delivery_screen.dart';
import 'home_screen.dart';
import '../widgets/fuoco_bottom_nav.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  String? _couponError;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      resizeToAvoidBottomInset: true,
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
                    'My Cart',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.black87),
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
                          const Text(
                            'Your cart is empty',
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                              (route) => false,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA500),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Add Items',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Scrollable list items
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final cartItem = cartItems[index];
                              final item = cartItem.item;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
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
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.asset(
                                        item.imageUrl,
                                        width: 70,
                                        height: 70,
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
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '৳${item.price.toInt()}',
                                            style: const TextStyle(
                                              color: Color(0xFFFFA500),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildQuantityButton(
                                          Icons.remove,
                                          () => ref
                                              .read(cartProvider.notifier)
                                              .decrementQuantity(item.id),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            cartItem.quantity.toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        _buildQuantityButton(
                                          Icons.add,
                                          () => ref
                                              .read(cartProvider.notifier)
                                              .incrementQuantity(item.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Sticky Bottom Panel
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Coupon Input Section
                              if (appliedCoupon == null) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 46,
                                        child: TextField(
                                          controller: _couponController,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            hintText: 'Enter Coupon / Promo Code',
                                            errorText: _couponError,
                                            errorStyle: const TextStyle(height: 0),
                                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                            filled: true,
                                            fillColor: const Color(0xFFF8F9FA),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Color(0xFFFFA500)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 46,
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
                                          backgroundColor: const Color(0xFFFFA500),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '💡 Try WELCOME50, FUOCO100, or FREE50',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFA5D6A7)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Promo '${appliedCoupon.code}' (৳${discount.toInt()} Off)",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(couponProvider.notifier).clearCoupon();
                                        },
                                        child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 12),
                              
                              // Price Breakdown List
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                  Text('৳${totalPrice.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                              if (appliedCoupon != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Discount', style: TextStyle(fontSize: 13, color: Colors.red)),
                                    Text('-৳${discount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              ],
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Text('৳${grandTotal.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFA500))),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Checkout Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const DeliveryScreen()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFA500),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 3,
                                    shadowColor: const Color(0xFFFFA500).withOpacity(0.3),
                                  ),
                                  child: const Text(
                                    'Proceed to Delivery',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.grey[700]),
      ),
    );
  }
}
