import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final addressServiceProvider = Provider((ref) => AddressService());

class AddressService {
  final List<Map<String, dynamic>> _dummyAddresses = [];
  final StreamController<List<Map<String, dynamic>>> _addressesController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Future<void> addAddress(Map<String, dynamic> addressData) async {
    final newAddress = {
      ...addressData,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'createdAt': DateTime.now(),
    };
    _dummyAddresses.insert(0, newAddress);
    _addressesController.add(List.from(_dummyAddresses));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Stream<List<Map<String, dynamic>>> getAddresses() async* {
    yield List.from(_dummyAddresses);
    yield* _addressesController.stream;
  }

  Future<void> deleteAddress(String addressId) async {
    _dummyAddresses.removeWhere((address) => address['id'] == addressId);
    _addressesController.add(List.from(_dummyAddresses));
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
