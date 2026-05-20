import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';
import '../providers/language_provider.dart';
import '../widgets/fuoco_bottom_nav.dart';
import 'home_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  late Stream<List<Map<String, dynamic>>> ordersStream;
  String _selectedFilter = 'All orders';
  final Set<String> _expandedOrders = {};
  
  RangeValues _priceRange = const RangeValues(0, 5000);
  RangeValues _tempPriceRange = const RangeValues(0, 5000);
  
  String _statusFilter = 'All';
  String _tempStatusFilter = 'All';
  
  String _dateFilter = 'All';
  String _tempDateFilter = 'All';
  
  String _paymentFilter = 'All';
  String _tempPaymentFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Cache the stream to prevent recreating it on every widget rebuild
    ordersStream = ref.read(orderServiceProvider).getUserOrders();
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
            // Custom Header (Mockup style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                  ),
                  Text(
                    ref.tr('my_order'),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_outlined, color: Colors.black87),
                    onPressed: () {
                      _showFilterBottomSheet(context);
                    },
                  ),
                ],
              ),
            ),

            // Filter Tabs (Mockup style)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  _buildFilterTab('All orders'),
                  _buildFilterTab('Active'),
                  _buildFilterTab('Cancelled'),
                ],
              ),
            ),

            // Order List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: ordersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading orders: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  final orders = snapshot.data!;
                  
                  // Filter orders based on selected tab and all active filters
                  final filteredOrders = orders.where((order) {
                    final status = order['status'] ?? 'Pending';
                    final total = (order['totalAmount'] ?? 0.0) as num;
                    final paymentMethod = (order['paymentMethod'] ?? 'COD').toString().toLowerCase();
                    
                    // 1. Price range filter
                    if (total < _priceRange.start || total > _priceRange.end) {
                      return false;
                    }
                    
                    // 2. Tab status filter
                    if (_selectedFilter == 'Active') {
                      if (status != 'Pending' && status != 'Processing') return false;
                    } else if (_selectedFilter == 'Cancelled') {
                      if (status != 'Cancelled') return false;
                    }

                    // 3. Granular Order Status filter from sheet
                    if (_statusFilter != 'All') {
                      if (status.toString().toLowerCase() != _statusFilter.toLowerCase()) {
                        return false;
                      }
                    }

                    // 4. Payment Method filter from sheet
                    if (_paymentFilter != 'All') {
                      if (paymentMethod != _paymentFilter.toLowerCase()) {
                        return false;
                      }
                    }

                    // 5. Date Range filter from sheet
                    if (_dateFilter != 'All' && order['createdAt'] != null) {
                      final timestamp = order['createdAt'] as dynamic;
                      final date = (timestamp is DateTime) ? timestamp : (timestamp as dynamic).toDate();
                      final now = DateTime.now();
                      
                      if (_dateFilter == 'Today') {
                        final todayStart = DateTime(now.year, now.month, now.day);
                        if (date.isBefore(todayStart)) return false;
                      } else if (_dateFilter == 'Last 7 Days') {
                        final sevenDaysAgo = now.subtract(const Duration(days: 7));
                        if (date.isBefore(sevenDaysAgo)) return false;
                      } else if (_dateFilter == 'Last 30 Days') {
                        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
                        if (date.isBefore(thirtyDaysAgo)) return false;
                      }
                    }

                    return true;
                  }).toList();

                  if (filteredOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[350]),
                          const SizedBox(height: 12),
                          Text(
                            ref.tr('no_filtered_orders').replaceAll('{0}', _selectedFilter == 'All orders' ? ref.tr('all_orders') : _selectedFilter == 'Active' ? ref.tr('active') : ref.tr('cancelled')),
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const FuocoBottomNav(currentIndex: 2),
      floatingActionButton: const FuocoFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFilterTab(String title) {
    bool isSelected = _selectedFilter == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.article_outlined, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          ref.tr('no_orders_yet'),
          style: const TextStyle(color: Colors.grey, fontSize: 18),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFED145B),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(ref.tr('order_now'), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'Pending';
    final total = order['totalAmount'] ?? 0.0;
    final items = order['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty ? items[0] : null;
    final String orderId = order['id']?.toString() ?? "162432";
    final bool isExpanded = _expandedOrders.contains(orderId);
    final String displayOrderId = orderId.length >= 6 ? orderId.substring(0, 6).toUpperCase() : orderId.toUpperCase();
    
    // Status text and color logic
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String statusText = 'Pending';
    Color statusColor = Colors.orange;
    String arrivalTime = '25 mins';
    
    if (status == 'Delivered') {
      statusText = 'Delivered';
      statusColor = Colors.green;
      arrivalTime = 'Completed';
    } else if (status == 'Cancelled') {
      statusText = 'Cancelled';
      statusColor = Colors.red;
      arrivalTime = 'Cancelled';
    } else if (status == 'Processing') {
      statusText = 'Food on the way';
      statusColor = Theme.of(context).primaryColor;
      arrivalTime = '20 mins';
    } else {
      statusText = 'Preparing';
      statusColor = Colors.orange;
      arrivalTime = '30 mins';
    }

    final String firstItemName = firstItem != null ? firstItem['name'] : 'Delicious Meal';
    final int firstItemQuantity = firstItem != null ? (firstItem['quantity'] as num).toInt() : 1;
    final String? firstItemImageUrl = firstItem != null ? firstItem['imageUrl'] as String? : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Image, Title, Price, Order ID
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildItemImage(firstItemImageUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstItemName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: items.length > 1
                          ? () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedOrders.remove(orderId);
                                } else {
                                  _expandedOrders.add(orderId);
                                }
                              });
                            }
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            items.length > 1
                                ? (isExpanded
                                    ? 'Show less'
                                    : '${firstItemQuantity} Pcs (+${items.length - 1} more)')
                                : '${firstItemQuantity} Pcs',
                            style: TextStyle(
                              fontSize: 13,
                              color: items.length > 1 ? Theme.of(context).primaryColor : Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (items.length > 1) ...[
                            const SizedBox(width: 4),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '#$displayOrderId',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          // Expanded Items List
          if (isExpanded)
            Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item['name']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              'x${item['quantity']}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F1F5)),
          const SizedBox(height: 16),
          
          // Row 2: Arrival Time, Total Amount & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.tr('estimated_arrival'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arrivalTime,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      ref.tr('total_amount'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${total.toInt()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ref.tr('now'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 3: Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showInvoiceDialog(context, order);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[200]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    ref.tr('invoice'),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showTrackingBottomSheet(context, order);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    ref.tr('track_order'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(),
        );
      } else {
        return Image.asset(
          imageUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(),
        );
      }
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 70,
      height: 70,
      color: const Color(0xFFF1F1F5),
      child: const Icon(Icons.fastfood, color: Colors.orange, size: 30),
    );
  }

  void _showInvoiceDialog(BuildContext context, Map<String, dynamic> order) {
    final total = order['totalAmount'] ?? 0.0;
    final items = order['items'] as List<dynamic>? ?? [];
    final address = order['address'] ?? 'No address provided';
    final paymentMethod = order['paymentMethod'] ?? 'COD';
    final String orderId = order['id'] ?? '';
    final String shortId = orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId;

    final createdAt = order['createdAt'];
    String dateStr = '';
    if (createdAt != null) {
      if (createdAt is DateTime) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final day = createdAt.day.toString().padLeft(2, '0');
        final month = months[createdAt.month - 1];
        final year = createdAt.year;
        final hour = createdAt.hour > 12 ? createdAt.hour - 12 : (createdAt.hour == 0 ? 12 : createdAt.hour);
        final min = createdAt.minute.toString().padLeft(2, '0');
        final ampm = createdAt.hour >= 12 ? 'PM' : 'AM';
        dateStr = '$day $month $year, $hour:$min $ampm';
      } else {
        dateStr = createdAt.toString();
      }
    } else {
      dateStr = 'Just Now';
    }

    final double deliveryFee = 50.0;
    final double subtotal = (total - deliveryFee) > 0 ? (total - deliveryFee) : total;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Receipt Header
                    Container(
                      color: const Color(0xFFED145B).withValues(alpha: 0.03),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFED145B),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFED145B).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'FUOCO OUTLET',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order ID: #FQ-$shortId',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref.tr('order_items') ?? 'ORDER ITEMS',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Items Grid
                          ...items.map((item) {
                            final price = item['price'] ?? 0.0;
                            final quantity = item['quantity'] ?? 1;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2D3142),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'x$quantity',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Text(
                                    '৳${(price * quantity).toInt()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2D3142),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 16),
                          const DashedDivider(color: Color(0xFFE5E9F2)),
                          const SizedBox(height: 16),

                          // Summary Breakdown
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ref.tr('subtotal'),
                                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '৳${subtotal.toInt()}',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2D3142), fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ref.tr('delivery_fee'),
                                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '৳${deliveryFee.toInt()}',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2D3142), fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ref.tr('total_amount'),
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D3142), fontSize: 15),
                              ),
                              Text(
                                '৳${total.toInt()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFED145B),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const DashedDivider(color: Color(0xFFE5E9F2)),
                          const SizedBox(height: 20),

                          // Delivery Info Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Color(0xFFED145B), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      ref.tr('delivery_address'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey[600],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3142),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Icon(Icons.payment_rounded, color: Colors.blueAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      ref.tr('payment_method_caps'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey[600],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: paymentMethod.toUpperCase() == 'COD' 
                                        ? Colors.orange.withValues(alpha: 0.1) 
                                        : const Color(0xFFED145B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    paymentMethod.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: paymentMethod.toUpperCase() == 'COD' 
                                          ? Colors.orange[800] 
                                          : const Color(0xFFED145B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          
                          // Close Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFED145B), Color(0xFFF93B7D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFED145B).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                ref.tr('close'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTrackingBottomSheet(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] ?? 'Pending';
    
    int currentStep = 0;
    if (status == 'Delivered') {
      currentStep = 3;
    } else if (status == 'Processing') {
      currentStep = 2;
    } else if (status == 'Cancelled') {
      currentStep = -1;
    } else {
      currentStep = 1; // Pending / Preparing
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                ref.tr('track_progress'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (currentStep == -1)
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.cancel_outlined, color: Colors.red, size: 60),
                      const SizedBox(height: 12),
                      Text(
                        ref.tr('order_cancelled'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    _buildTrackingStep(
                      title: 'Order Placed',
                      subtitle: 'We have received your order',
                      isCompleted: currentStep >= 0,
                      isActive: currentStep == 0,
                    ),
                    _buildTrackingLine(isCompleted: currentStep > 0),
                    _buildTrackingStep(
                      title: 'Preparing Food',
                      subtitle: 'Our chef is preparing your delicious meal',
                      isCompleted: currentStep >= 1,
                      isActive: currentStep == 1,
                    ),
                    _buildTrackingLine(isCompleted: currentStep > 1),
                    _buildTrackingStep(
                      title: 'Food on the Way',
                      subtitle: 'Our rider is delivering your food',
                      isCompleted: currentStep >= 2,
                      isActive: currentStep == 2,
                    ),
                    _buildTrackingLine(isCompleted: currentStep > 2),
                    _buildTrackingStep(
                      title: 'Delivered',
                      subtitle: 'Enjoy your meal!',
                      isCompleted: currentStep >= 3,
                      isActive: currentStep == 3,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
  }) {
    Color iconColor = isCompleted ? Theme.of(context).primaryColor : Colors.grey[300]!;
    if (isActive) iconColor = Colors.orange;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.radio_button_unchecked,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.black87 : Colors.grey[400],
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingLine({required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      width: 2,
      height: 25,
      color: isCompleted ? Theme.of(context).primaryColor : Colors.grey[200],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    _tempPriceRange = _priceRange;
    _tempStatusFilter = _statusFilter;
    _tempDateFilter = _dateFilter;
    _tempPaymentFilter = _paymentFilter;

    final Set<String> expandedSections = {'Price Range'};

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        ref.tr('filter_orders'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Price Range Section
                    _buildFilterAccordionRow(
                      title: ref.tr('price_range') ?? 'Price Range',
                      isExpanded: expandedSections.contains('Price Range'),
                      onToggle: () {
                        setModalState(() {
                          if (expandedSections.contains('Price Range')) {
                            expandedSections.remove('Price Range');
                          } else {
                            expandedSections.add('Price Range');
                          }
                        });
                      },
                      child: Column(
                        children: [
                          RangeSlider(
                            values: _tempPriceRange,
                            min: 0,
                            max: 5000,
                            divisions: 50,
                            activeColor: Theme.of(context).primaryColor,
                            inactiveColor: Colors.grey[200],
                            labels: RangeLabels(
                              '৳${_tempPriceRange.start.toInt()}',
                              '৳${_tempPriceRange.end.toInt()}',
                            ),
                            onChanged: (values) {
                              setModalState(() {
                                _tempPriceRange = values;
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '৳${_tempPriceRange.start.toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '৳${_tempPriceRange.end.toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F1F5)),

                    // Order Status Section
                    _buildFilterAccordionRow(
                      title: ref.tr('order_status') ?? 'Order Status',
                      isExpanded: expandedSections.contains('Order Status'),
                      onToggle: () {
                        setModalState(() {
                          if (expandedSections.contains('Order Status')) {
                            expandedSections.remove('Order Status');
                          } else {
                            expandedSections.add('Order Status');
                          }
                        });
                      },
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['All', 'Pending', 'Processing', 'Delivered', 'Cancelled'].map((status) {
                          final bool isSelected = _tempStatusFilter == status;
                          return ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            checkmarkColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                _tempStatusFilter = status;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F1F5)),

                    // Date Range Section
                    _buildFilterAccordionRow(
                      title: ref.tr('date_range') ?? 'Date Range',
                      isExpanded: expandedSections.contains('Date Range'),
                      onToggle: () {
                        setModalState(() {
                          if (expandedSections.contains('Date Range')) {
                            expandedSections.remove('Date Range');
                          } else {
                            expandedSections.add('Date Range');
                          }
                        });
                      },
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['All', 'Today', 'Last 7 Days', 'Last 30 Days'].map((dateRange) {
                          final bool isSelected = _tempDateFilter == dateRange;
                          return ChoiceChip(
                            label: Text(dateRange),
                            selected: isSelected,
                            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            checkmarkColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                _tempDateFilter = dateRange;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F1F5)),

                    // Payment Method Section
                    _buildFilterAccordionRow(
                      title: ref.tr('payment_method') ?? 'Payment Method',
                      isExpanded: expandedSections.contains('Payment Method'),
                      onToggle: () {
                        setModalState(() {
                          if (expandedSections.contains('Payment Method')) {
                            expandedSections.remove('Payment Method');
                          } else {
                            expandedSections.add('Payment Method');
                          }
                        });
                      },
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['All', 'bKash', 'Nagad', 'Card', 'COD'].map((method) {
                          final bool isSelected = _tempPaymentFilter == method;
                          return ChoiceChip(
                            label: Text(method),
                            selected: isSelected,
                            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            checkmarkColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                _tempPaymentFilter = method;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reset and Apply Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _tempPriceRange = const RangeValues(0, 5000);
                                _tempStatusFilter = 'All';
                                _tempDateFilter = 'All';
                                _tempPaymentFilter = 'All';
                              });
                              setState(() {
                                _priceRange = const RangeValues(0, 5000);
                                _statusFilter = 'All';
                                _dateFilter = 'All';
                                _paymentFilter = 'All';
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[200]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              ref.tr('reset') ?? 'Reset',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _priceRange = _tempPriceRange;
                                _statusFilter = _tempStatusFilter;
                                _dateFilter = _tempDateFilter;
                                _paymentFilter = _tempPaymentFilter;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              ref.tr('apply'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildFilterAccordionRow({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: child,
            ),
          ),
      ],
    );
  }
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;

  const DashedDivider({
    super.key,
    this.height = 1.0,
    this.color = Colors.grey,
    this.dashWidth = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
