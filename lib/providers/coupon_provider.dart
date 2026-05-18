import 'package:flutter_riverpod/flutter_riverpod.dart';

class Coupon {
  final String code;
  final double discountAmount;
  final double discountPercent; // e.g. 0.1 for 10%
  final double minOrder;
  final String description;

  const Coupon({
    required this.code,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    this.minOrder = 0.0,
    required this.description,
  });
}

class CouponNotifier extends Notifier<Coupon?> {
  @override
  Coupon? build() {
    return null; // By default, no coupon applied
  }

  bool applyCoupon(String code, double orderTotal) {
    final cleanCode = code.trim().toUpperCase();
    
    // Define available premium coupon codes
    final List<Coupon> availableCoupons = [
      const Coupon(
        code: 'WELCOME50',
        discountPercent: 0.5,
        minOrder: 150.0,
        description: '50% off on your first order above ৳150',
      ),
      const Coupon(
        code: 'FUOCO100',
        discountAmount: 100.0,
        minOrder: 300.0,
        description: 'Flat ৳100 off on orders above ৳300',
      ),
      const Coupon(
        code: 'FREE50',
        discountAmount: 50.0,
        minOrder: 100.0,
        description: 'Get flat ৳50 discount on any meal above ৳100',
      ),
    ];

    try {
      final coupon = availableCoupons.firstWhere((c) => c.code == cleanCode);
      if (orderTotal >= coupon.minOrder) {
        state = coupon;
        return true;
      }
      return false; // Under minimum order requirement
    } catch (_) {
      return false; // Invalid coupon code
    }
  }

  void clearCoupon() {
    state = null;
  }
}

final couponProvider = NotifierProvider<CouponNotifier, Coupon?>(() {
  return CouponNotifier();
});
