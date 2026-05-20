import 'package:flutter_riverpod/flutter_riverpod.dart';

final addressServiceProvider = Provider((ref) => AddressService());

class AddressService {
  final List<Map<String, dynamic>> _dummyAddresses = [];

  Future<void> addAddress(Map<String, dynamic> addressData) async {
    final newAddress = {
      ...addressData,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'createdAt': DateTime.now(),
    };
    _dummyAddresses.insert(0, newAddress);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Stream<List<Map<String, dynamic>>> getAddresses() {
    return Stream.value(_dummyAddresses);
  }

  Future<void> deleteAddress(String addressId) async {
    _dummyAddresses.removeWhere((address) => address['id'] == addressId);
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
