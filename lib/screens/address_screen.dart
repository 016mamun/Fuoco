import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/address_service.dart';
import 'map_picker_screen.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesStream = ref.watch(addressServiceProvider).getAddresses();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                          'Delivery Addresses',
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
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: addressesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      final addresses = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          return _buildAddressCard(context, ref, address);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressSheet(context, ref),
        backgroundColor: const Color(0xFFFFA500),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New Address', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text(
          'No addresses saved yet',
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildAddressCard(BuildContext context, WidgetRef ref, Map<String, dynamic> address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFA500).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on, color: Color(0xFFFFA500)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                address['label'] ?? 'Home',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (address['phone'] != null)
              Text(
                address['phone'],
                style: const TextStyle(fontSize: 12, color: Color(0xFFFFA500), fontWeight: FontWeight.w600),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (address['name'] != null)
              Text(
                address['name'],
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            Text(
              address['city'] ?? '',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () {
            ref.read(addressServiceProvider).deleteAddress(address['id']);
          },
        ),
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context, WidgetRef ref) {
    final labelController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Address',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              _buildTextField(labelController, 'Detailed Address (Home, Office or Street)', Icons.label_outline),
              const SizedBox(height: 16),
              _buildTextField(nameController, 'Receiver Name', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(phoneController, 'Phone Number', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(cityController, 'City', Icons.location_city),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapPickerScreen()),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    labelController.text = result['address'];
                  }
                },
                icon: const Icon(Icons.map_outlined, color: Color(0xFFFFA500)),
                label: const Text(
                  'Pick from Google Maps',
                  style: TextStyle(color: Color(0xFFFFA500), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (labelController.text.isNotEmpty && cityController.text.isNotEmpty) {
                      await ref.read(addressServiceProvider).addAddress({
                        'label': labelController.text,
                        'name': nameController.text,
                        'phone': phoneController.text,
                        'city': cityController.text,
                      });
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'Save Address',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFFFA500), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}
