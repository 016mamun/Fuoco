import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_screen.dart';
import '../services/address_service.dart';
import 'map_picker_screen.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  String? _selectedAddressId;
  Map<String, dynamic>? _selectedAddress;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final addressesStream = ref.watch(addressServiceProvider).getAddresses();

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
                          'Deliver To',
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
                        const Text(
                          'Select Saved Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Saved Addresses List
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: addressesStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text('No saved addresses found. Please add one in profile.', 
                                  style: TextStyle(color: Colors.grey)),
                                ),
                              );
                            }

                            final addresses = snapshot.data!;
                            return Column(
                              children: addresses.map((addr) => _buildAddressItem(addr)).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                        const Text(
                          'OR Enter Manual Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Manual Input Fields (Restored Address Field)
                        _buildTextField(_nameController, 'Receiver Name', Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField(_phoneController, 'Phone Number', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),
                        _buildTextField(_addressController, 'Full Address', Icons.location_on_outlined),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MapPickerScreen()),
                            );
                            if (result != null && result is Map<String, dynamic>) {
                              setState(() {
                                _addressController.text = result['address'];
                                _selectedAddressId = null; // Unselect saved address if manual is used
                                _selectedAddress = null;
                              });
                            }
                          },
                          icon: const Icon(Icons.map_outlined, color: Color(0xFFFFA500)),
                          label: const Text(
                            'Pick from Google Maps',
                            style: TextStyle(color: Color(0xFFFFA500), fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_cityController, 'City', Icons.location_city_outlined),
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
            onPressed: () {
              String finalAddress = "";
              if (_selectedAddress != null) {
                finalAddress = "${_selectedAddress!['address'] ?? ""}, ${_selectedAddress!['city'] ?? ""}";
              } else {
                finalAddress = "${_addressController.text}, ${_cityController.text}";
              }

              if (finalAddress.trim().isEmpty || finalAddress.trim() == ",") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select or enter a delivery location')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentScreen(address: finalAddress)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              shadowColor: const Color(0xFFFFA500).withOpacity(0.4),
            ),
            child: const Text(
              'Continue to Payment',
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

  Widget _buildAddressItem(Map<String, dynamic> address) {
    bool isSelected = _selectedAddressId == address['id'];
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAddressId = null;
            _selectedAddress = null;
          } else {
            _selectedAddressId = address['id'];
            _selectedAddress = address;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFA500).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA500) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFFFFA500).withOpacity(0.1) 
                  : Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFFFA500) 
                    : const Color(0xFFFFA500).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.location_on_rounded,
                color: isSelected ? Colors.white : const Color(0xFFFFA500),
                size: 22,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          address['label']?.split(',').first ?? 'Home',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected ? const Color(0xFFFFA500) : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.stars_rounded, color: Color(0xFFFFA500), size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address['label'] ?? '',
                    style: TextStyle(
                      fontSize: 13, 
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFFFA500), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
