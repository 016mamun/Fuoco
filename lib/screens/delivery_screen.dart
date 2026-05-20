import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_screen.dart';
import '../services/address_service.dart';
import '../providers/language_provider.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            // Clean Flat Header (matching My Cart)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    ref.tr('deliver_to'),
                    style: const TextStyle(
                      color: Color(0xFF2D3142),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 40), // Balanced spacing for alignment
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.tr('select_saved_address'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3142),
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
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100, width: 1.0),
                            ),
                            child: Center(
                              child: Text(
                                ref.tr('no_saved_addresses'),
                                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
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
                    Text(
                      ref.tr('or_manual_details'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Manual Input Fields
                    _buildTextField(_nameController, ref.tr('receiver_name'), Icons.person_outline_rounded),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, ref.tr('phone_number'), Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField(_addressController, ref.tr('full_address'), Icons.location_on_outlined),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_rounded, color: Color(0xFFED145B), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              ref.tr('pick_from_map'),
                              style: const TextStyle(
                                color: Color(0xFFED145B),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_cityController, ref.tr('city'), Icons.location_city_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
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
                String finalAddress = "";
                if (_selectedAddress != null) {
                  finalAddress = "${_selectedAddress!['label'] ?? ""}, ${_selectedAddress!['city'] ?? ""}";
                } else {
                  finalAddress = "${_addressController.text}, ${_cityController.text}";
                }

                if (finalAddress.trim().isEmpty || finalAddress.trim() == ",") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ref.tr('please_select_location'))),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentScreen(address: finalAddress)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                ref.tr('continue_payment'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressItem(Map<String, dynamic> address) {
    bool isSelected = _selectedAddressId == address['id'];
    final String type = address['type'] ?? 'Home';
    IconData typeIcon = Icons.location_on_rounded;
    if (type == 'Home') {
      typeIcon = Icons.home_rounded;
    } else if (type == 'Office') {
      typeIcon = Icons.work_rounded;
    }

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
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFED145B).withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFED145B) : Colors.grey.shade100,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFED145B).withValues(alpha: 0.1) 
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check_circle_rounded : typeIcon,
                color: isSelected ? const Color(0xFFED145B) : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          type,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isSelected ? const Color(0xFFED145B) : const Color(0xFF2D3142),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address['label'] ?? '',
                    style: TextStyle(
                      fontSize: 12, 
                      color: Colors.grey[600],
                      height: 1.3,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFED145B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
