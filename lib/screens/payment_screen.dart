import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';
import '../services/order_service.dart';
import '../widgets/fuoco_bottom_nav.dart';
import 'orders_screen.dart';
import 'home_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String address;
  const PaymentScreen({super.key, required this.address});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? _selectedMethod;
  bool _isProcessing = false;

  final TextEditingController _transactionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _transactionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'bkash',
      'name': 'bKash',
      'imageUrl': 'https://logos-download.com/wp-content/uploads/2022/01/BKash_Logo.png',
      'color': const Color(0xFFE2136E),
    },
    {
      'id': 'nagad',
      'name': 'Nagad',
      'imageUrl': 'https://www.tbsnews.net/sites/default/files/styles/infograph/public/images/2021/03/17/nagad_logo.png',
      'color': const Color(0xFFED1C24),
    },
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card_outlined,
      'color': Colors.blue,
    },
    {
      'id': 'cod',
      'name': 'Cash on Delivery',
      'icon': Icons.moped_outlined,
      'color': const Color(0xFFFFA500),
    },
  ];

  Map<String, dynamic>? paymentIntent;

  Future<void> _makePayment(double amount) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stripe payment is currently available on Mobile devices only.')),
      );
      return;
    }
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: 'your_client_secret_from_backend',
          style: ThemeMode.light,
          merchantDisplayName: 'Fuoco Restaurant',
        ),
      );
      await _displayPaymentSheet(amount);
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stripe setup incomplete. Please check your keys and backend.')),
      );
    }
  }

  Future<void> _displayPaymentSheet(double amount) async {
    try {
      await Stripe.instance.presentPaymentSheet();
      
      try {
        final cartItems = ref.read(cartProvider).values.toList();
        await ref.read(orderServiceProvider).placeOrder(
              items: cartItems,
              totalAmount: amount,
              address: widget.address,
              paymentMethod: 'card',
            ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Order save error (non-blocking): $e');
      }

      if (mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
    const double deliveryFee = 50.0;
    final finalAmount = totalPrice + deliveryFee - discount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBody: true,
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFFA500),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Payment Method',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          // Curved Content Area
          Expanded(
            child: Stack(
              children: [
                // Orange background behind the curve (Only at the top)
                Container(
                  height: 50,
                  color: const Color(0xFFFFA500),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                                  Text('৳${totalPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery Fee', style: TextStyle(color: Colors.grey)),
                                  Text('৳50', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                                ],
                              ),
                              if (discount > 0) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Promo Discount (${appliedCoupon!.code})', style: const TextStyle(color: Colors.red)),
                                    Text('-৳${discount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              ],
                              const Divider(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '৳${finalAmount.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFA500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Order ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text('#FUO-78921', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Select Payment Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._paymentMethods.map((method) => _buildPaymentMethodItem(method)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () async {
                    if (_selectedMethod == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('অনুগ্রহ করে একটি পেমেন্ট মেথড সিলেক্ট করুন'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (_selectedMethod == 'bkash' || _selectedMethod == 'nagad') {
                      if (_phoneController.text.isEmpty || _transactionController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter your ${_selectedMethod == 'bkash' ? 'bKash' : 'Nagad'} number and Transaction ID'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                    }

                    if (_selectedMethod == 'card') {
                      _makePayment(finalAmount);
                    } else {
                      setState(() => _isProcessing = true);
                      // Save to Firestore (best-effort, don't block UI)
                      try {
                        final cartItems = ref.read(cartProvider).values.toList();
                        await ref.read(orderServiceProvider).placeOrder(
                              items: cartItems,
                              totalAmount: finalAmount,
                              address: widget.address,
                              paymentMethod: _selectedMethod!,
                            ).timeout(const Duration(seconds: 5));
                      } catch (e) {
                        debugPrint('Order save error (non-blocking): $e');
                      }
                      if (mounted) {
                        setState(() => _isProcessing = false);
                        _showSuccessDialog(context);
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              shadowColor: const Color(0xFFFFA500).withOpacity(0.4),
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Confirm & Pay Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(Map<String, dynamic> method) {
    bool isSelected = _selectedMethod == method['id'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method['id'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8F0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA500) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFFFA500).withOpacity(0.15) : Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: method['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: method['imageUrl'] != null
                        ? ClipOval(
                            child: Image.network(
                              method['imageUrl'],
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.account_balance_wallet_outlined,
                                color: method['color'],
                              ),
                            ),
                          )
                        : Icon(
                            method['icon'],
                            color: method['color'],
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    method['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.black : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFFFA500),
                    size: 28,
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                  ),
              ],
            ),
            if (isSelected && (method['id'] == 'bkash' || method['id'] == 'nagad'))
              Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCC80).withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFA500).withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2.0),
                              child: Icon(Icons.info_outline, size: 16, color: Color(0xFFFFA500)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('অনুগ্রহ করে নিচের নাম্বারে ${method['name']} করুন:', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone_android, size: 20, color: Color(0xFFFFA500)),
                                SizedBox(width: 8),
                                Text('+8801677951406', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1.2)),
                                SizedBox(width: 8),
                                Text('(Personal)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'আপনার ${method['name']} নাম্বার',
                      labelStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFA500), width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFFFA500)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _transactionController,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'ট্রানজ্যাকশন আইডি (TrxID)',
                      labelStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFA500), width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      prefixIcon: const Icon(Icons.receipt_long_outlined, color: Color(0xFFFFA500)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext outerContext) {
    ref.read(cartProvider.notifier).clearCart();
    ref.read(couponProvider.notifier).clearCoupon();
    Navigator.of(outerContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _OrderSuccessPage()),
      (route) => false,
    );
  }
}

class _OrderSuccessPage extends StatelessWidget {
  const _OrderSuccessPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 32),
              const Text(
                'Order Successful!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your delicious food is on the way.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Track My Order',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Back to Home',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
