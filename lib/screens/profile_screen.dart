import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../widgets/fuoco_bottom_nav.dart';
import 'orders_screen.dart';
import 'address_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _profilePicBase64;
  bool _isLoadingPic = true;

  bool _orderUpdates = true;
  bool _offersPromo = true;
  bool _newsletter = false;
  String _selectedLanguage = 'English';
  
  String _savedBkash = '';
  String _savedNagad = '';
  String _savedCard = '';

  @override
  void initState() {
    super.initState();
    _loadProfilePic();
    _loadUserSettings();
  }

  Future<void> _loadProfilePic() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()!.containsKey('profile_picture')) {
          if (mounted) {
            setState(() {
              _profilePicBase64 = doc.data()!['profile_picture'] as String;
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading profile pic: $e');
      }
    }
    if (mounted) setState(() => _isLoadingPic = false);
  }

  Future<void> _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            if (mounted) {
              setState(() {
                _orderUpdates = data['order_updates'] ?? true;
                _offersPromo = data['offers_promo'] ?? true;
                _newsletter = data['newsletter'] ?? false;
                _selectedLanguage = data['language'] ?? 'English';
                _savedBkash = data['saved_bkash'] ?? '';
                _savedNagad = data['saved_nagad'] ?? '';
                _savedCard = data['saved_card'] ?? '';
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading settings: $e');
      }
    }
  }

  Future<void> _updateProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 70,
      );
      if (image != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);
          
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'profile_picture': base64String,
          }, SetOptions(merge: true));

          if (mounted) {
            setState(() {
              _profilePicBase64 = base64String;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showEditProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final nameController = TextEditingController(text: user.displayName);
    final emailController = TextEditingController(text: user.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context); // Close sheet to pick image
                    await _updateProfilePicture();
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _isLoadingPic
                              ? const CircularProgressIndicator()
                              : (_profilePicBase64 != null
                                  ? Image.memory(
                                      base64Decode(_profilePicBase64!),
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.person, size: 60, color: Colors.grey),
                                    )
                                  : (user.photoURL != null && user.photoURL!.isNotEmpty
                                      ? (kIsWeb || user.photoURL!.startsWith('http') || user.photoURL!.startsWith('blob:')
                                          ? Image.network(
                                              user.photoURL!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.person, size: 60, color: Colors.grey),
                                            )
                                          : Image.file(
                                              File(user.photoURL!),
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.person, size: 60, color: Colors.grey),
                                            ))
                                      : const Icon(Icons.person, size: 60, color: Colors.grey))),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA500),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Email Address (Cannot be changed)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isNotEmpty) {
                        await user.updateDisplayName(nameController.text.trim());
                        await user.reload();
                        if (mounted) {
                          setState(() {});
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBody: true,
      body: Column(
        children: [
          // Premium Header with Profile Info
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFFA500),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Column(
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _updateProfilePicture,
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: ClipOval(
                                  child: _isLoadingPic
                                      ? const Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: CircularProgressIndicator(color: Colors.white),
                                        )
                                      : (_profilePicBase64 != null
                                          ? Image.memory(
                                              base64Decode(_profilePicBase64!),
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.person, color: Colors.white, size: 50),
                                            )
                                          : (user?.photoURL != null && user!.photoURL!.isNotEmpty
                                              ? (kIsWeb || user.photoURL!.startsWith('http') || user.photoURL!.startsWith('blob:')
                                                  ? Image.network(
                                                      user.photoURL!,
                                                      fit: BoxFit.cover,
                                                      width: 80,
                                                      height: 80,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          const Icon(Icons.person, color: Colors.white, size: 50),
                                                    )
                                                  : Image.file(
                                                      File(user.photoURL!),
                                                      fit: BoxFit.cover,
                                                      width: 80,
                                                      height: 80,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          const Icon(Icons.person, color: Colors.white, size: 50),
                                                    ))
                                              : const Icon(Icons.person, color: Colors.white, size: 50))),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Color(0xFFFFA500), size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Fuoco User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user?.email ?? 'user@example.com',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showEditProfileDialog,
                          icon: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ],
                    ),
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
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
                    child: Column(
                      children: [
                        _buildProfileOption(
                          icon: Icons.shopping_bag_outlined,
                          title: 'My Orders',
                          subtitle: 'History and tracking',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrdersScreen()),
                          ),
                        ),
                        _buildProfileOption(
                          icon: Icons.location_on_outlined,
                          title: 'Delivery Address',
                          subtitle: 'Manage your locations',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddressScreen()),
                          ),
                        ),
                        _buildProfileOption(
                          icon: Icons.credit_card_outlined,
                          title: 'Payment Methods',
                          subtitle: 'Cards and wallets',
                          onTap: () => _showPaymentMethodsBottomSheet(context),
                        ),
                        _buildProfileOption(
                          icon: Icons.notifications_none_outlined,
                          title: 'Notifications',
                          subtitle: 'Manage alerts',
                          onTap: () => _showNotificationsBottomSheet(context),
                        ),
                        _buildProfileOption(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'App preferences',
                          onTap: () => _showSettingsBottomSheet(context),
                        ),
                        const SizedBox(height: 20),
                        _buildProfileOption(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out of your account',
                          iconColor: Colors.red,
                          textColor: Colors.red,
                          onTap: () {
                            _showLogoutDialog(context, ref);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FuocoBottomNav(currentIndex: 1),
      floatingActionButton: const FuocoFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
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
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFFFFA500)).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFFFFA500)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodsBottomSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bkashController = TextEditingController(text: _savedBkash);
    final nagadController = TextEditingController(text: _savedNagad);
    final cardController = TextEditingController(text: _savedCard);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Payment Methods',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Mobile Wallets',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: bkashController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Saved bKash Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(Icons.phone_android, color: Color(0xFFFFA500)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: nagadController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Saved Nagad Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(Icons.phone_android, color: Color(0xFFFFA500)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Saved Credit/Debit Cards',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: cardController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Card Number (e.g. **** **** **** 4242)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(Icons.credit_card, color: Color(0xFFFFA500)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final bkash = bkashController.text.trim();
                          final nagad = nagadController.text.trim();
                          final card = cardController.text.trim();

                          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                            'saved_bkash': bkash,
                            'saved_nagad': nagad,
                            'saved_card': card,
                          }, SetOptions(merge: true));

                          setState(() {
                            _savedBkash = bkash;
                            _savedNagad = nagad;
                            _savedCard = card;
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment methods updated successfully!'),
                                backgroundColor: Color(0xFFFFA500),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA500),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Save Methods', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Notifications Settings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SwitchListTile(
                      title: const Text('Order Status Updates', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Receive push alerts on your food delivery progress'),
                      value: _orderUpdates,
                      activeColor: const Color(0xFFFFA500),
                      onChanged: (val) async {
                        setModalState(() => _orderUpdates = val);
                        setState(() => _orderUpdates = val);
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'order_updates': val,
                        }, SetOptions(merge: true));
                      },
                    ),
                    const Divider(height: 24),
                    
                    SwitchListTile(
                      title: const Text('Offers & Promotions', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Get real-time discount vouchers and menu deals'),
                      value: _offersPromo,
                      activeColor: const Color(0xFFFFA500),
                      onChanged: (val) async {
                        setModalState(() => _offersPromo = val);
                        setState(() => _offersPromo = val);
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'offers_promo': val,
                        }, SetOptions(merge: true));
                      },
                    ),
                    const Divider(height: 24),
                    
                    SwitchListTile(
                      title: const Text('Fuoco Newsletter', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Get weekly updates from partner restaurants'),
                      value: _newsletter,
                      activeColor: const Color(0xFFFFA500),
                      onChanged: (val) async {
                        setModalState(() => _newsletter = val);
                        setState(() => _newsletter = val);
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'newsletter': val,
                        }, SetOptions(merge: true));
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'App Preferences',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'App Language',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              setModalState(() => _selectedLanguage = 'English');
                              setState(() => _selectedLanguage = 'English');
                              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                'language': 'English',
                              }, SetOptions(merge: true));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedLanguage == 'English'
                                    ? const Color(0xFFFFA500).withOpacity(0.1)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedLanguage == 'English'
                                      ? const Color(0xFFFFA500)
                                      : Colors.grey[200]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'English',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedLanguage == 'English'
                                        ? const Color(0xFFFFA500)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              setModalState(() => _selectedLanguage = 'বাংলা');
                              setState(() => _selectedLanguage = 'বাংলা');
                              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                'language': 'বাংলা',
                              }, SetOptions(merge: true));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedLanguage == 'বাংলা'
                                    ? const Color(0xFFFFA500).withOpacity(0.1)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedLanguage == 'বাংলা'
                                      ? const Color(0xFFFFA500)
                                      : Colors.grey[200]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'বাংলা',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedLanguage == 'বাংলা'
                                        ? const Color(0xFFFFA500)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 36),
                    
                    const Text(
                      'Visuals & Theme',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    SwitchListTile(
                      title: const Text('Enable Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Switch the app view to dark theme style'),
                      value: false,
                      activeColor: const Color(0xFFFFA500),
                      onChanged: (val) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dark theme is coming soon in the next release!'),
                            backgroundColor: Color(0xFFFFA500),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    
                    TextButton(
                      onPressed: () {
                        _showDeleteAccountDialog(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_forever_outlined),
                          SizedBox(width: 8),
                          Text(
                            'Delete My Account',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to permanently delete your Fuoco account? This action is irreversible and all your orders, addresses, and settings data will be destroyed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                  await user.delete();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e. Please re-authenticate first.')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
