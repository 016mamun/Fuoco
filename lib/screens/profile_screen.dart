import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/fuoco_bottom_nav.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final pic = prefs.getString('profile_picture');
    if (pic != null && mounted) {
      setState(() {
        _profilePicBase64 = pic;
      });
    }
    if (mounted) setState(() => _isLoadingPic = false);
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    ref.read(isDarkModeProvider.notifier).setTheme(isDark);
    if (mounted) {
      setState(() {
        _orderUpdates = prefs.getBool('order_updates') ?? true;
        _offersPromo = prefs.getBool('offers_promo') ?? true;
        _newsletter = prefs.getBool('newsletter') ?? false;
        _savedBkash = prefs.getString('saved_bkash') ?? '';
        _savedNagad = prefs.getString('saved_nagad') ?? '';
        _savedCard = prefs.getString('saved_card') ?? '';
      });
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
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_picture', base64String);

        if (mounted) {
          setState(() {
            _profilePicBase64 = base64String;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showEditProfileDialog() {
    final user = ref.read(authServiceProvider);
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
            top: 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 24),
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
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                            color: Color(0xFFED145B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFED145B), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFED145B), size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  readOnly: true,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  decoration: InputDecoration(
                    labelText: 'Email Address (Cannot be changed)',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade100)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFED145B), Color(0xFFF93B7D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFED145B).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
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
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Column(
        children: [
          // Premium Header with Profile Info
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFED145B), Color(0xFFF93B7D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFED145B).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                child: Column(
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _isLoadingPic
                                      ? const Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
                                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFED145B), size: 14),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'user@example.com',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (user != null)
                          IconButton(
                            onPressed: _showEditProfileDialog,
                            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
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
                // Gradient background behind the curve (Only at the top)
                Container(
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFED145B), Color(0xFFF93B7D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    child: Column(
                      children: [


                        _buildProfileOption(
                          icon: Icons.shopping_bag_outlined,
                          title: ref.tr('my_orders'),
                          subtitle: ref.tr('my_orders_sub'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrdersScreen()),
                          ),
                        ),
                        _buildProfileOption(
                          icon: Icons.location_on_outlined,
                          title: ref.tr('delivery_address'),
                          subtitle: ref.tr('delivery_address_sub'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddressScreen()),
                          ),
                        ),
                        _buildProfileOption(
                          icon: Icons.credit_card_outlined,
                          title: ref.tr('payment_methods'),
                          subtitle: ref.tr('payment_methods_sub'),
                          onTap: () => _showPaymentMethodsBottomSheet(context),
                        ),
                        _buildProfileOption(
                          icon: Icons.notifications_none_outlined,
                          title: ref.tr('notifications'),
                          subtitle: ref.tr('notifications_sub'),
                          onTap: () => _showNotificationsBottomSheet(context),
                        ),
                        _buildProfileOption(
                          icon: Icons.settings_outlined,
                          title: ref.tr('settings'),
                          subtitle: ref.tr('settings_sub'),
                          onTap: () => _showSettingsBottomSheet(context),
                        ),
                        const SizedBox(height: 10),
                        if (user != null)
                          _buildProfileOption(
                            icon: Icons.logout_rounded,
                            title: ref.tr('logout'),
                            subtitle: ref.tr('logout_sub'),
                            iconColor: Colors.red,
                            textColor: Colors.red,
                            onTap: () {
                              _showLogoutDialog(context, ref);
                            },
                          )
                        else
                          _buildProfileOption(
                            icon: Icons.login_rounded,
                            title: ref.tr('login'),
                            subtitle: ref.tr('login_sub'),
                            iconColor: const Color(0xFFED145B),
                            textColor: const Color(0xFFED145B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, width: 1.0),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(0xFFED145B)).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor ?? const Color(0xFFED145B), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor ?? (isDark ? Colors.white : const Color(0xFF2D3142)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12, 
                        color: isDark ? Colors.grey[400] : Colors.grey.shade500, 
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.grey[600] : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              ref.tr('logout'),
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 18, 
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3142),
              ),
            ),
          ],
        ),
        content: Text(
          ref.tr('logout_confirm'),
          style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authServiceProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(ref.tr('logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, int activeTab, VoidCallback onTap) {
    final isSelected = index == activeTab;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFED145B) : (isDark ? const Color(0xFF252528) : const Color(0xFFF1F1F5)),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBkashCardPreview(String number) {
    final displayNum = number.isEmpty ? 'Not Linked' : number;
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFD11550), Color(0xFFED145B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFED145B).withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'bKash Wallet',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fuoco Mobile Pay', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
              Icon(Icons.phone_android_rounded, color: Colors.white.withValues(alpha: 0.8), size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNagadCardPreview(String number) {
    final displayNum = number.isEmpty ? 'Not Linked' : number;
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF9100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nagad Wallet',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fuoco Mobile Pay', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
              Icon(Icons.phone_android_rounded, color: Colors.white.withValues(alpha: 0.8), size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardPreview(String number) {
    final displayNum = number.isEmpty ? '•••• •••• •••• ••••' : number;
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF0F2027)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2027).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Credit / Debit Card',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              Icon(Icons.credit_card, color: Colors.white.withValues(alpha: 0.8), size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fuoco Secure Pay', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: Container(
                      width: 24,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodsBottomSheet(BuildContext context) {
    final bkashController = TextEditingController(text: _savedBkash);
    final nagadController = TextEditingController(text: _savedNagad);
    final cardController = TextEditingController(text: _savedCard);
    int activePaymentTab = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        ref.tr('payment_methods'),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF2D3142)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Custom Tab Buttons
                    Row(
                      children: [
                        _buildTabButton('bKash', 0, activePaymentTab, () => setModalState(() => activePaymentTab = 0)),
                        _buildTabButton('Nagad', 1, activePaymentTab, () => setModalState(() => activePaymentTab = 1)),
                        _buildTabButton('Card', 2, activePaymentTab, () => setModalState(() => activePaymentTab = 2)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Interactive Card Preview
                    if (activePaymentTab == 0)
                      _buildBkashCardPreview(bkashController.text)
                    else if (activePaymentTab == 1)
                      _buildNagadCardPreview(nagadController.text)
                    else
                      _buildCreditCardPreview(cardController.text),

                    const SizedBox(height: 24),
                    
                    Text(
                      ref.tr('account_details'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    if (activePaymentTab == 0)
                      TextField(
                        controller: bkashController,
                        keyboardType: TextInputType.phone,
                        onChanged: (val) => setModalState(() {}),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF2D3142)),
                        decoration: InputDecoration(
                          labelText: ref.tr('saved_bkash'),
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF252528) : Colors.white,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFED145B), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFFED145B), size: 20),
                        ),
                      )
                    else if (activePaymentTab == 1)
                      TextField(
                        controller: nagadController,
                        keyboardType: TextInputType.phone,
                        onChanged: (val) => setModalState(() {}),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF2D3142)),
                        decoration: InputDecoration(
                          labelText: ref.tr('saved_nagad'),
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF252528) : Colors.white,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFED145B), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFFED145B), size: 20),
                        ),
                      )
                    else
                      TextField(
                        controller: cardController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setModalState(() {}),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF2D3142)),
                        decoration: InputDecoration(
                          labelText: ref.tr('card_number'),
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF252528) : Colors.white,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFED145B), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFFED145B), size: 20),
                        ),
                      ),

                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFED145B), Color(0xFFF93B7D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFED145B).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('saved_bkash', bkashController.text);
                            await prefs.setString('saved_nagad', nagadController.text);
                            await prefs.setString('saved_card', cardController.text);
                            
                            setState(() {
                              _savedBkash = bkashController.text;
                              _savedNagad = nagadController.text;
                              _savedCard = cardController.text;
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment methods updated successfully!'),
                                  backgroundColor: Color(0xFFED145B),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(ref.tr('save_methods'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
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

  Widget _buildSwitchContainer({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 14, 
            color: isDark ? Colors.white : const Color(0xFF2D3142),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12, 
            color: isDark ? Colors.grey[400] : Colors.grey.shade500, 
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        activeColor: const Color(0xFFED145B),
        activeTrackColor: const Color(0xFFED145B).withValues(alpha: 0.2),
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        ref.tr('notifications_settings'),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF2D3142)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSwitchContainer(
                      title: ref.tr('order_updates'),
                      subtitle: ref.tr('order_updates_sub'),
                      value: _orderUpdates,
                      onChanged: (val) async {
                        setModalState(() => _orderUpdates = val);
                        setState(() => _orderUpdates = val);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('order_updates', val);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? 'Order status updates enabled!' : 'Order status updates disabled.'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFED145B),
                            ),
                          );
                        }
                      },
                    ),
                    
                    _buildSwitchContainer(
                      title: ref.tr('offers_promo'),
                      subtitle: ref.tr('offers_promo_sub'),
                      value: _offersPromo,
                      onChanged: (val) async {
                        setModalState(() => _offersPromo = val);
                        setState(() => _offersPromo = val);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('offers_promo', val);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? 'Voucher & promo alerts enabled!' : 'Voucher & promo alerts disabled.'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFED145B),
                            ),
                          );
                        }
                      },
                    ),
                    
                    _buildSwitchContainer(
                      title: ref.tr('newsletter'),
                      subtitle: ref.tr('newsletter_sub'),
                      value: _newsletter,
                      onChanged: (val) async {
                        setModalState(() => _newsletter = val);
                        setState(() => _newsletter = val);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('newsletter', val);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? 'Newsletter subscribed!' : 'Newsletter unsubscribed.'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFED145B),
                            ),
                          );
                        }
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final selectedLanguage = ref.watch(languageProvider);
            final isDarkMode = ref.watch(isDarkModeProvider);

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        ref.tr('app_preferences'),
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w900, 
                          color: isDark ? Colors.white : const Color(0xFF2D3142),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      ref.tr('app_language'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ref.read(languageProvider.notifier).setLanguage('English');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Language set to English'),
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Color(0xFFED145B),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedLanguage == 'English'
                                    ? const Color(0xFFED145B).withValues(alpha: 0.05)
                                    : (isDark ? const Color(0xFF252528) : Colors.white),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedLanguage == 'English'
                                      ? const Color(0xFFED145B)
                                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                  width: selectedLanguage == 'English' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'English',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: selectedLanguage == 'English'
                                        ? const Color(0xFFED145B)
                                        : (isDark ? Colors.white70 : const Color(0xFF2D3142)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ref.read(languageProvider.notifier).setLanguage('বাংলা');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ভাষা পরিবর্তন করে বাংলায় করা হয়েছে'),
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Color(0xFFED145B),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedLanguage == 'বাংলা'
                                    ? const Color(0xFFED145B).withValues(alpha: 0.05)
                                    : (isDark ? const Color(0xFF252528) : Colors.white),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedLanguage == 'বাংলা'
                                      ? const Color(0xFFED145B)
                                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                  width: selectedLanguage == 'বাংলা' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'বাংলা',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: selectedLanguage == 'বাংলা'
                                        ? const Color(0xFFED145B)
                                        : (isDark ? Colors.white70 : const Color(0xFF2D3142)),
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSwitchContainer(
                      title: 'Enable Dark Mode',
                      subtitle: 'Switch the app view to dark theme style',
                      value: isDarkMode,
                      onChanged: (val) async {
                        ref.read(isDarkModeProvider.notifier).setTheme(val);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('is_dark_mode', val);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? 'Dark mode enabled!' : 'Light mode enabled.'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFED145B),
                            ),
                          );
                        }
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
                      child: Row(
                        children: [
                          const Icon(Icons.delete_forever_rounded),
                          const SizedBox(width: 8),
                          Text(
                            ref.tr('delete_account'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              ref.tr('delete_account'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          ref.tr('delete_account_confirm'),
          style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(authServiceProvider);
              if (user != null) {
                try {
                  await Future.delayed(const Duration(milliseconds: 500));
                  await Future.delayed(const Duration(milliseconds: 500));
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
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(ref.tr('delete_permanently'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
