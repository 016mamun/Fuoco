import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../providers/cart_provider.dart';

import '../providers/search_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

import 'cart_screen.dart';
import '../widgets/fuoco_bottom_nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Page Controller and Timer for the auto-sliding banner
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Filter variables next to search bar
  String _sortBy = 'Popularity';
  double _minPriceFilter = 0;
  double _maxPriceFilter = 3000;
  bool _isFilterApplied = false;
  


  final List<String> _bannerImages = [
    'assets/images/banner-1.gif',
    'assets/images/banner-2.gif',
    'assets/images/banner-3.gif',
  ];

  // Mock categories for the horizontal chips
  final List<String> _categories = [
    'Popular',
    'Meatbox',
    'Burger',
    'Pizza',
    'Combo',
    'Rice',
  ];
  String _selectedCategory = 'Popular';
  final ScrollController _categoryScrollController = ScrollController();

  // Mock food items data
  final List<FoodItem> _foodItems = [
    FoodItem(
      id: 'a1',
      name: 'Bang Bang Wings',
      description: 'Delicious bang bang wings',
      price: 250,
      imageUrl: 'assets/images/Appetizers/bang bang wings.png',
      category: 'Appetizers',
      rating: 4.8,
    ),
    FoodItem(
      id: 'a2',
      name: 'Bbq-wings',
      description: 'Delicious bbq-wings',
      price: 220,
      imageUrl: 'assets/images/Appetizers/bbq-wings.png',
      category: 'Appetizers',
      rating: 4.2,
    ),
    FoodItem(
      id: 'a3',
      name: 'Cheese Puff Corn Dog',
      description: 'Delicious cheese puff corn dog',
      price: 150,
      imageUrl: 'assets/images/Appetizers/cheese puff corn dog.jpg',
      category: 'Appetizers',
      isPopular: true,
      rating: 4.6,
    ),
    FoodItem(
      id: 'a4',
      name: 'Chicken Lollipop',
      description: 'Delicious chicken lollipop',
      price: 180,
      imageUrl: 'assets/images/Appetizers/chicken lollipop.png',
      category: 'Appetizers',
    ),
    FoodItem(
      id: 'a5',
      name: 'Chicken Strips',
      description: 'Delicious chicken strips',
      price: 200,
      imageUrl: 'assets/images/Appetizers/chicken strips.jpg',
      category: 'Appetizers',
    ),
    FoodItem(
      id: 'a6',
      name: 'Chicken-cheese Ball',
      description: 'Delicious chicken-cheese ball',
      price: 210,
      imageUrl: 'assets/images/Appetizers/chicken-cheese ball.png',
      category: 'Appetizers',
    ),
    FoodItem(
      id: 'a7',
      name: 'Hand Crafted Wedges',
      description: 'Delicious hand crafted wedges',
      price: 120,
      imageUrl: 'assets/images/Appetizers/hand crafted wedges.jpg',
      category: 'Appetizers',
    ),
    FoodItem(
      id: 'a8',
      name: 'Hot Fries',
      description: 'Delicious hot fries',
      price: 100,
      imageUrl: 'assets/images/Appetizers/hot fries.jpg',
      category: 'Appetizers',
    ),
    FoodItem(
      id: 'a9',
      name: 'Naga Drumstick',
      description: 'Delicious naga drumstick',
      price: 190,
      imageUrl: 'assets/images/Appetizers/naga drumstick.jpg',
      category: 'Appetizers',
    ),
    FoodItem(
      id: 'a10',
      name: 'Naga Wings',
      description: 'Delicious naga wings',
      price: 230,
      imageUrl: 'assets/images/Appetizers/naga wings.png',
      category: 'Appetizers',
      isPopular: true,
    ),

    FoodItem(
      id: 'b1',
      name: 'Beef & Bacon Burger',
      description: 'Delicious beef & bacon burger',
      price: 350,
      imageUrl: 'assets/images/Burger/beef & bacon burger.jpg',
      category: 'Burger',
      rating: 4.7,
    ),
    FoodItem(
      id: 'b2',
      name: 'Beef Cheese Burger',
      description: 'Delicious beef cheese burger',
      price: 300,
      imageUrl: 'assets/images/Burger/beef cheese burger.jpg',
      category: 'Burger',
      isPopular: true,
      rating: 4.9,
    ),
    FoodItem(
      id: 'b3',
      name: 'Chicken Big Vite',
      description: 'Delicious chicken big vite',
      price: 280,
      imageUrl: 'assets/images/Burger/chicken big vite.jpg',
      category: 'Burger',
    ),
    FoodItem(
      id: 'b4',
      name: 'Chicken With Cheese',
      description: 'Delicious chicken with cheese',
      price: 250,
      imageUrl: 'assets/images/Burger/chicken with cheese.jpg',
      category: 'Burger',
    ),
    FoodItem(
      id: 'b5',
      name: 'Sausage Delight Burger',
      description: 'Delicious sausage delight burger',
      price: 270,
      imageUrl: 'assets/images/Burger/sausage delight burger.jpg',
      category: 'Burger',
      isPopular: true,
    ),

    FoodItem(
      id: 'c1',
      name: 'Bachelor Combo',
      description: 'Delicious bachelor combo',
      price: 450,
      imageUrl: 'assets/images/Combo/bachelor combo.jpg',
      category: 'Combo',
    ),
    FoodItem(
      id: 'c2',
      name: 'Burger Lover Combo',
      description: 'Delicious burger lover combo',
      price: 550,
      imageUrl: 'assets/images/Combo/burger lover combo.jpg',
      category: 'Combo',
    ),
    FoodItem(
      id: 'c3',
      name: 'Etai Bastob',
      description: 'Delicious etai bastob',
      price: 400,
      imageUrl: 'assets/images/Combo/etai bastob.jpg',
      category: 'Combo',
    ),
    FoodItem(
      id: 'c4',
      name: 'Family Combo',
      description: 'Delicious family combo',
      price: 950,
      imageUrl: 'assets/images/Combo/family combo.jpg',
      category: 'Combo',
    ),
    FoodItem(
      id: 'c5',
      name: 'Love At First Bite',
      description: 'Delicious love at first bite',
      price: 600,
      imageUrl: 'assets/images/Combo/love at first bite.jpg',
      category: 'Combo',
    ),
    FoodItem(
      id: 'c6',
      name: 'Meat Box Mania',
      description: 'Delicious meat box mania',
      price: 500,
      imageUrl: 'assets/images/Combo/meat box mania.jpg',
      category: 'Combo',
      isPopular: true,
    ),
    FoodItem(
      id: 'c7',
      name: 'Pizza Deal',
      description: 'Delicious pizza deal',
      price: 750,
      imageUrl: 'assets/images/Combo/pizza deal.jpg',
      category: 'Combo',
    ),
    FoodItem(
      id: 'c8',
      name: 'Pizza Lover Combo',
      description: 'Delicious pizza lover combo',
      price: 850,
      imageUrl: 'assets/images/Combo/pizza lover combo.jpg',
      category: 'Combo',
    ),
    FoodItem(
      id: 'c9',
      name: 'Pure Bachelor Combo',
      description: 'Delicious pure bachelor combo',
      price: 420,
      imageUrl: 'assets/images/Combo/pure bachelor combo.png',
      category: 'Combo',
    ),
    FoodItem(
      id: 'c10',
      name: 'Set The Perfect Date',
      description: 'Delicious set the perfect date',
      price: 800,
      imageUrl: 'assets/images/Combo/set the perfect date.jpg',
      category: 'Combo',
      isPopular: true,
    ),
    FoodItem(
      id: 'c11',
      name: 'Toofan Combo',
      description: 'Delicious toofan combo',
      price: 700,
      imageUrl: 'assets/images/Combo/toofan combo.jpg',
      category: 'Combo',
    ),

    FoodItem(
      id: 'm1',
      name: 'Meat Ball',
      description: 'Delicious meat ball',
      price: 200,
      imageUrl: 'assets/images/Meatbox/Meat ball.jpg',
      category: 'Meatbox',
    ),
    FoodItem(
      id: 'm2',
      name: 'Bbq Meatbox',
      description: 'Delicious bbq meatbox',
      price: 250,
      imageUrl: 'assets/images/Meatbox/bbq meatbox.jpg',
      category: 'Meatbox',
      isPopular: true,
    ),
    FoodItem(
      id: 'm3',
      name: 'Cheese Overload',
      description: 'Delicious cheese overload',
      price: 300,
      imageUrl: 'assets/images/Meatbox/cheese overload.jpg',
      category: 'Meatbox',
    ),
    FoodItem(
      id: 'm4',
      name: 'Classic Meatbox',
      description: 'Delicious classic meatbox',
      price: 220,
      imageUrl: 'assets/images/Meatbox/classic meatbox.jpg',
      category: 'Meatbox',
    ),
    FoodItem(
      id: 'm5',
      name: 'Fuoco Special',
      description: 'Delicious fuoco special',
      price: 350,
      imageUrl: 'assets/images/Meatbox/fuoco special.jpg',
      category: 'Meatbox',
      isPopular: true,
    ),
    FoodItem(
      id: 'm6',
      name: 'Naga Bomb',
      description: 'Delicious naga bomb',
      price: 280,
      imageUrl: 'assets/images/Meatbox/naga bomb.jpg',
      category: 'Meatbox',
    ),

    FoodItem(
      id: 'p1',
      name: 'Bbq Blast Pizza',
      description: 'Delicious bbq blast pizza',
      price: 650,
      imageUrl: 'assets/images/Pizza/bbq blast pizza.jpg',
      category: 'Pizza',
    ),
    FoodItem(
      id: 'p2',
      name: 'Chicken Dynamite',
      description: 'Delicious chicken dynamite',
      price: 700,
      imageUrl: 'assets/images/Pizza/chicken dynamite.jpg',
      category: 'Pizza',
      isPopular: true,
    ),
    FoodItem(
      id: 'p3',
      name: 'Fuoco Special Pizza',
      description: 'Delicious fuoco special pizza',
      price: 850,
      imageUrl: 'assets/images/Pizza/fuoco special.jpg',
      category: 'Pizza',
    ),
    FoodItem(
      id: 'p4',
      name: 'Hot Mexicana',
      description: 'Delicious hot mexicana',
      price: 750,
      imageUrl: 'assets/images/Pizza/hot mexicana.jpg',
      category: 'Pizza',
      isPopular: true,
    ),
    FoodItem(
      id: 'p5',
      name: 'Meat Lovers Pizza',
      description: 'Delicious meat lovers pizza',
      price: 800,
      imageUrl: 'assets/images/Pizza/meat lovers pizza.jpg',
      category: 'Pizza',
    ),
    FoodItem(
      id: 'p6',
      name: 'Sausage Tausage Pizza',
      description: 'Delicious sausage tausage pizza',
      price: 680,
      imageUrl: 'assets/images/Pizza/sausage tausage pizza.jpg',
      category: 'Pizza',
    ),

    FoodItem(
      id: 'r1',
      name: 'Butterfly Platter',
      description: 'Delicious butterfly platter',
      price: 350,
      imageUrl: 'assets/images/Rice/butterfly platter.png',
      category: 'Rice',
      isPopular: true,
    ),
    FoodItem(
      id: 'r2',
      name: 'Cheesy Steak Platter',
      description: 'Delicious cheesy steak platter',
      price: 400,
      imageUrl: 'assets/images/Rice/cheesy steak platter.jpg',
      category: 'Rice',
    ),
    FoodItem(
      id: 'r3',
      name: 'Cream Steak',
      description: 'Delicious cream steak',
      price: 380,
      imageUrl: 'assets/images/Rice/cream steak.png',
      category: 'Rice',
    ),
    FoodItem(
      id: 'r4',
      name: 'Hungry Pro Max',
      description: 'Delicious hungry pro max',
      price: 450,
      imageUrl: 'assets/images/Rice/hungry pro max.jpg',
      category: 'Rice',
      isPopular: true,
    ),
    FoodItem(
      id: 'r5',
      name: 'Rice To Meet You',
      description: 'Delicious rice to meet you',
      price: 320,
      imageUrl: 'assets/images/Rice/rice to meet you.jpg',
      category: 'Rice',
    ),
    FoodItem(
      id: 'r6',
      name: 'Tandoori Platter',
      description: 'Delicious tandoori platter',
      price: 370,
      imageUrl: 'assets/images/Rice/tandoori platter.jpg',
      category: 'Rice',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Set up auto-slide timer every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentPage < _bannerImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Always Sticky Main Header
            Container(
              color: const Color(0xFFED145B),
              child: _buildHeader(),
            ),
            
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Promo Banner (Scrolls away)
                  SliverToBoxAdapter(
                    child: Container(
                      color: const Color(0xFFED145B),
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
                      child: _buildPromoBanner(),
                    ),
                  ),
                  
                  // Sticky Categories (Sticks below Main Header)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      height: 170.0,
                      child: Container(
                        color: const Color(0xFFED145B),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCategoryChips(),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Left Arrow
                                  GestureDetector(
                                    onTap: () => _scrollCategories(false),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFED145B).withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 14,
                                        color: Color(0xFFED145B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Right Arrow
                                  GestureDetector(
                                    onTap: () => _scrollCategories(true),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFED145B).withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: Color(0xFFED145B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Food Grid in Background
                  SliverToBoxAdapter(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            ref.tr('cat_$_selectedCategory'),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFoodGrid(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const FuocoFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const FuocoBottomNav(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    final isSearching = ref.watch(searchBarVisibilityProvider);
    final selectedBranch = ref.watch(selectedBranchProvider);
    
    if (!isSearching && _searchQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _searchQuery = '';
          _searchController.clear();
        });
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Location and Action Icons (Notification & Cart)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Location Switcher Capsule (Pill)
              Expanded(
                child: GestureDetector(
                onTap: () => _showBranchSwitcherBottomSheet(context, ref),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ref.tr('branch'),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 12,
                                ),
                              ],
                            ),
                            Text(
                              selectedBranch.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
              const SizedBox(width: 12),
              // Right side: Notification + Cart Badge + Sign In/Up
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (ref.watch(authServiceProvider) == null) ...[
                    // Cart Badge
                    _buildCartBadge(),
                    const SizedBox(width: 10),
                    // Sign In Premium Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFED145B),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        ref.tr('sign_in'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sign Up Premium Button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        ref.tr('sign_up'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Notification Icon
                    GestureDetector(
                      onTap: () => _showNotificationQuickView(),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Cart Badge
                    _buildCartBadge(),
                  ],
                ],
              ),
            ],
          ),
          if (isSearching) ...[
            const SizedBox(height: 16),
            // Row 2: Search Bar
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: ref.tr('search_hint'),
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFED145B), size: 22),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          child: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                        ),
                      if (_searchQuery.isNotEmpty) const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showFilterBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFED145B).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: _isFilterApplied ? const Color(0xFFED145B) : Colors.grey[700],
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showBranchSwitcherBottomSheet(BuildContext context, WidgetRef ref) {
    final selectedBranch = ref.read(selectedBranchProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.tr('select_branch'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ref.tr('switch_outlet'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.grey[400] : const Color(0xFF9C9EA8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: branchesList.length,
                  itemBuilder: (context, index) {
                    final branch = branchesList[index];
                    final isSelected = branch.name == selectedBranch.name;
                    final isOpen = branch.isOpen;

                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedBranchProvider.notifier).selectBranch(branch);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFED145B).withValues(alpha: 0.04)
                              : (isDark ? const Color(0xFF252528) : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFED145B)
                                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            width: isSelected ? 2.0 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFED145B).withValues(alpha: 0.1)
                                    : (isDark ? Colors.grey[850] : Colors.grey[100]),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                color: isSelected
                                    ? const Color(0xFFED145B)
                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        branch.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: isSelected
                                              ? const Color(0xFFED145B)
                                              : (isDark ? Colors.white : const Color(0xFF2D3142)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOpen
                                              ? const Color(0xFF2ECC71).withValues(alpha: 0.12)
                                              : Colors.grey.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isOpen ? ref.tr('open') : ref.tr('closed'),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: isOpen
                                                ? const Color(0xFF27AE60)
                                                : (isDark ? Colors.grey[400] : Colors.grey.shade600),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    branch.address,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      height: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFFED145B),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationQuickView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: Color(0xFFED145B), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildNotificationItem(
                'Order Delivered Successfully!',
                'Your delicious burger has been delivered to your doorstep.',
                '2 mins ago',
                true,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                'Special 20% discount offer!',
                'Get 20% flat discount on your next order using coupon code FUOCO20.',
                '1 hour ago',
                false,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                'Rider is approaching!',
                'Your rider Rahat is 500m away from your location.',
                '3 hours ago',
                false,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(String title, String body, String time, bool isNew) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFED145B).withValues(alpha: 0.06) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew ? const Color(0xFFED145B).withValues(alpha: 0.15) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNew ? const Color(0xFFED145B).withValues(alpha: 0.15) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: isNew ? const Color(0xFFED145B) : Colors.grey[600],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isNew ? const Color(0xFFED145B) : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartBadge() {
    return Consumer(
      builder: (context, ref, child) {
        final cartMap = ref.watch(cartProvider);
        final totalItems = cartMap.values.fold(0, (sum, item) => sum + item.quantity);
        return Badge(
          isLabelVisible: totalItems > 0,
          label: Text(
            totalItems.toString(),
            style: const TextStyle(
              color: Color(0xFFED145B),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          backgroundColor: Colors.white,
          offset: const Offset(4, -4),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            ),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromoBanner() {
    return AspectRatio(
      aspectRatio: 16 / 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFED145B).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _bannerImages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _bannerImages[index],
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFED145B),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Get special discount', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const Text('Up to 95%', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))),
                                      child: const Text('Claim voucher', style: TextStyle(color: const Color(0xFFED145B), fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 32.0; // 16 left + 16 right
    final spacing = 12.0;
    final itemWidth = (screenWidth - horizontalPadding - (3 * spacing)) / 4.0;

    return SizedBox(
      height: 110,
      child: ListView.builder(
        controller: _categoryScrollController,
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          String catImageUrl = '';
          final itemsInCategory = _foodItems.where((item) => item.category == category).toList();
          if (itemsInCategory.isNotEmpty) {
            catImageUrl = itemsInCategory.first.imageUrl;
          } else if (_foodItems.isNotEmpty) {
            catImageUrl = _foodItems.first.imageUrl;
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              width: itemWidth,
              margin: EdgeInsets.only(
                right: index == _categories.length - 1 ? 0 : spacing,
              ),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFED145B) : const Color(0xFFFFCCBC),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFFED145B).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipOval(
                      child: catImageUrl.isNotEmpty 
                        ? Image.asset(
                            catImageUrl, 
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.fastfood, color: isSelected ? const Color(0xFFED145B) : Colors.grey, size: 20),
                          )
                        : Icon(Icons.fastfood, color: isSelected ? const Color(0xFFED145B) : Colors.grey, size: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ref.tr('cat_$category'),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _scrollCategories(bool forward) {
    if (!_categoryScrollController.hasClients) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 32.0;
    final spacing = 12.0;
    final itemWidth = (screenWidth - horizontalPadding - (3 * spacing)) / 4.0;
    final double step = itemWidth + spacing;
    
    double targetOffset = _categoryScrollController.offset + (forward ? step : -step);
    
    targetOffset = targetOffset.clamp(
      _categoryScrollController.position.minScrollExtent,
      _categoryScrollController.position.maxScrollExtent,
    );
    
    _categoryScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildFoodGrid() {
    // Filter by category first
    List<FoodItem> filteredItems = _selectedCategory == 'Popular'
        ? _foodItems
        : _foodItems.where((item) => item.category == _selectedCategory).toList();

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) => 
        item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    } else if (_selectedCategory == 'Popular') {
      // If not searching and 'Popular' is selected, show popular items
      filteredItems = filteredItems.where((item) => item.isPopular).toList();
    }

    // Apply active filter: Price Range
    filteredItems = filteredItems.where((item) => 
      item.price >= _minPriceFilter && item.price <= _maxPriceFilter
    ).toList();

    // Apply active sorting
    if (_sortBy == 'Rating') {
      filteredItems.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'PriceLowToHigh') {
      filteredItems.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'PriceHighToLow') {
      filteredItems.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Popularity') {
      // Put popular items first
      filteredItems.sort((a, b) {
        if (a.isPopular && !b.isPopular) return -1;
        if (!a.isPopular && b.isPopular) return 1;
        return 0;
      });
    }

    if (filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(ref.tr('no_items_found'), style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GestureDetector(
          onTap: () => _showFoodDetailsBottomSheet(context, item),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                )
              ],
            ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.fastfood, color: isDark ? Colors.grey.shade600 : Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          item.rating.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 12),
                Text(
                  item.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '15 Min  |  200 Sell',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '৳${item.price.toInt()}',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFED145B) : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} ${ref.tr('added_to_cart')}'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: const Color(0xFFED145B),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: const Color(0xFFED145B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }


  void _showFoodDetailsBottomSheet(BuildContext context, FoodItem item) {
    int quantity = 1;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Cover Image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          child: Image.asset(
                            item.imageUrl,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 250,
                              color: const Color(0xFFFFF3E0),
                              child: const Icon(Icons.fastfood, size: 80, color: Color(0xFFED145B)),
                            ),
                          ),
                        ),
                        // Close floating button
                        Positioned(
                          top: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white70,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.black87, size: 20),
                            ),
                          ),
                        ),

                      ],
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge and Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFED145B).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: Color(0xFFED145B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.rating.toString(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '(45+ reviews)',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Food Title
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Delivery detail / Sell info
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text('15 Mins Delivery', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(width: 16),
                              Icon(Icons.local_fire_department, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text('200+ Sold', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                          const Divider(height: 32),
                          
                          // Food Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description.isNotEmpty 
                                ? item.description 
                                : 'Treat yourself to our premium ${item.name}, masterfully prepared by our chefs using only the freshest ingredients and local spices. It is rich, delicious, and cooked to absolute perfection. Guaranteed to satisfy your cravings!',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const Divider(height: 32),
                          
                          // Quantity and Price row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Price', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '৳${(item.price * quantity).toInt()}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFED145B),
                                    ),
                                  ),
                                ],
                              ),
                              // Counter
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (quantity > 1) {
                                        setModalState(() => quantity--);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.remove, size: 18, color: Colors.grey[700]),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      quantity.toString(),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() => quantity++);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.add, size: 18, color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Add to Cart Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: Consumer(
                              builder: (context, ref, child) {
                                return ElevatedButton(
                                  onPressed: () {
                                    ref.read(cartProvider.notifier).addItemWithQuantity(item, quantity);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$quantity Pcs of ${item.name} added to cart!'),
                                        backgroundColor: const Color(0xFFED145B),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFED145B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 5,
                                    shadowColor: const Color(0xFFED145B).withValues(alpha: 0.4),
                                  ),
                                  child: const Text(
                                    'Add to Cart',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Temp local state inside the sheet
    String tempSortBy = _sortBy;
    double tempMinPrice = _minPriceFilter;
    double tempMaxPrice = _maxPriceFilter;

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
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Sort By Section
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Popularity', 
                        isSelected: tempSortBy == 'Popularity', 
                        onTap: () => setModalState(() => tempSortBy = 'Popularity'),
                      ),
                      _buildFilterChip(
                        label: 'Rating', 
                        isSelected: tempSortBy == 'Rating', 
                        onTap: () => setModalState(() => tempSortBy = 'Rating'),
                      ),
                      _buildFilterChip(
                        label: 'Price: Low to High', 
                        isSelected: tempSortBy == 'PriceLowToHigh', 
                        onTap: () => setModalState(() => tempSortBy = 'PriceLowToHigh'),
                      ),
                      _buildFilterChip(
                        label: 'Price: High to Low', 
                        isSelected: tempSortBy == 'PriceHighToLow', 
                        onTap: () => setModalState(() => tempSortBy = 'PriceHighToLow'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Price Range Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '৳${tempMinPrice.toInt()} - ৳${tempMaxPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFED145B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: RangeValues(tempMinPrice, tempMaxPrice),
                    min: 0,
                    max: 3000,
                    divisions: 60,
                    activeColor: const Color(0xFFED145B),
                    inactiveColor: Colors.grey[200],
                    labels: RangeLabels(
                      '৳${tempMinPrice.toInt()}',
                      '৳${tempMaxPrice.toInt()}',
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        tempMinPrice = values.start;
                        tempMaxPrice = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Reset
                            setState(() {
                              _sortBy = 'Popularity';
                              _minPriceFilter = 0;
                              _maxPriceFilter = 3000;
                              _isFilterApplied = false;
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFED145B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Reset All',
                            style: TextStyle(color: Color(0xFFED145B), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Apply
                            setState(() {
                              _sortBy = tempSortBy;
                              _minPriceFilter = tempMinPrice;
                              _maxPriceFilter = tempMaxPrice;
                              _isFilterApplied = true;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFED145B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFED145B) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFED145B) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// Sticky Header Delegate
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
