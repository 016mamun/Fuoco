import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
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
                  const Text(
                    'My Order',
                    style: TextStyle(
                      color: Colors.black87,
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
                color: const Color(0xFFF1F1F5),
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
                            'No $_selectedFilter orders found',
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
        const Text(
          'No orders yet',
          style: TextStyle(color: Colors.grey, fontSize: 18),
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
          child: const Text('Order Now', style: TextStyle(color: Colors.white)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                      'Estimated Arrival',
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
                      'Total Amount',
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
                      'Now',
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
                    'Invoice',
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
                  child: const Text(
                    'Track Order',
                    style: TextStyle(
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          title: const Center(
            child: Text(
              'Order Invoice',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 10),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['name']} x${item['quantity']}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text('৳${((item['price'] ?? 0.0) * (item['quantity'] ?? 1)).toInt()}'),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee', style: TextStyle(color: Colors.grey)),
                    const Text('৳50'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '৳${total.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFED145B), fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                const Text('Delivery Address', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                const Text('Payment Method', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
      backgroundColor: Colors.white,
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
              const Text(
                'Track Order Progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (currentStep == -1)
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.red, size: 60),
                      SizedBox(height: 12),
                      Text(
                        'This order has been cancelled',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      ),
                      SizedBox(height: 20),
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
            color: iconColor.withOpacity(0.1),
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
      backgroundColor: Colors.white,
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
                    const Center(
                      child: Text(
                        'Filter Orders',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Price Range Section
                    _buildFilterAccordionRow(
                      title: 'Price Range',
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
                      title: 'Order Status',
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
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
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
                      title: 'Date Range',
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
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
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
                      title: 'Payment Method',
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
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
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
                              'Reset',
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
                            child: const Text(
                              'Apply',
                              style: TextStyle(
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
