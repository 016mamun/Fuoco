import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';

final orderServiceProvider = Provider((ref) => OrderService());

class OrderService {
  final List<Map<String, dynamic>> _dummyOrders = [];

  Future<void> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String address,
    required String paymentMethod,
  }) async {
    final orderData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userId': 'dummy-uid',
      'items': items.map((item) => {
        'name': item.item.name,
        'quantity': item.quantity,
        'price': item.item.price,
        'imageUrl': item.item.imageUrl,
      }).toList(),
      'totalAmount': totalAmount,
      'address': address,
      'paymentMethod': paymentMethod,
      'status': 'Pending',
      'createdAt': DateTime.now(),
    };
    
    _dummyOrders.insert(0, orderData);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Stream<List<Map<String, dynamic>>> getUserOrders() {
    return Stream.value(_dummyOrders);
  }
}
