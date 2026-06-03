import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final Restaurant restaurant;
  final int userId;
  final int? reservationId; // null when browsing without reservation

  const MenuScreen({
    super.key,
    required this.restaurant,
    required this.userId,
    this.reservationId,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  Map<int, bool> _favouriteItems = {};
  bool _initializingOrder = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.restaurant.menuCategories.length,
      vsync: this,
    );
    _loadFavourites();
    if (widget.reservationId != null) {
      _initOrder();
    }
  }

  // ── Initialize or fetch the active order for this reservation ──
  Future<void> _initOrder() async {
    if (_initializingOrder) return;
    setState(() => _initializingOrder = true);

    final cart = Provider.of<CartProvider>(context, listen: false);

    // If cart is already set for this reservation, skip
    if (cart.reservationId == widget.reservationId && cart.orderId != null) {
      setState(() => _initializingOrder = false);
      return;
    }

    try {
      final result = await _apiService.createOrGetOrder(
        userId: widget.userId,
        restaurantId: widget.restaurant.id,
        reservationId: widget.reservationId!,
      );

      if (result != null) {
        cart.setContext(
          orderId: result['orderId'],
          reservationId: widget.reservationId!,
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
        );

        // Sync existing items from backend into local cart
        final existingOrder =
            await _apiService.getOrderByReservation(widget.reservationId!);
        if (existingOrder != null) {
          final items = existingOrder['items'] as List? ?? [];
          for (final item in items) {
            // Only add if not already in local cart
            if (!cart.hasItem(item['menuItemId'])) {
              cart.addItem(
                menuItemId: item['menuItemId'],
                name: item['menuItemName'] ?? '',
                price: (item['price'] as num).toDouble(),
                imageUrl: item['menuItemImageUrl'],
              );
              // Adjust quantity to match backend
              final qty = (item['quantity'] as int? ?? 1) - 1;
              for (int i = 0; i < qty; i++) {
                cart.addItem(
                  menuItemId: item['menuItemId'],
                  name: item['menuItemName'] ?? '',
                  price: (item['price'] as num).toDouble(),
                );
              }
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _initializingOrder = false);
  }

  Future<void> _loadFavourites() async {
    for (var category in widget.restaurant.menuCategories) {
      for (var item in category.menuItems) {
        if (!mounted) return;
        final isFav =
            await _apiService.checkFavouriteItem(widget.userId, item.id);
        if (mounted) setState(() => _favouriteItems[item.id] = isFav);
      }
    }
  }

  Future<void> _toggleFavouriteItem(MenuItem item) async {
    final current = _favouriteItems[item.id] ?? false;
    setState(() => _favouriteItems[item.id] = !current);
    try {
      if (current) {
        await _apiService.removeFavouriteItem(widget.userId, item.id);
      } else {
        await _apiService.addFavouriteItem(widget.userId, item.id);
      }
    } catch (_) {
      setState(() => _favouriteItems[item.id] = current);
    }
  }

  // ── Add item to cart and sync with backend ──
  Future<void> _addToCart(MenuItem item) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (cart.orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need a confirmed reservation to order.'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }

    // Block adding items after bill has been requested
    final blockedStatuses = ['BillRequested', 'Paid', 'Completed'];
    if (blockedStatuses.contains(cart.orderStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your bill has been requested. No more items can be added.'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }

    cart.addItem(
      menuItemId: item.id,
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
    );

    // Sync to backend
    try {
      await _apiService.addItemToOrder(
        orderId: cart.orderId!,
        menuItemId: item.id,
        quantity: 1,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // ── Header ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.restaurant.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (widget.reservationId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF333333)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.table_restaurant,
                                      color: Color(0xFFB71C1C), size: 14),
                                  SizedBox(width: 4),
                                  Text('Ordering mode',
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Category Tabs ────────────────────────────────
                    if (widget.restaurant.menuCategories.isNotEmpty)
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: const Color(0xFFB71C1C),
                        labelColor: const Color(0xFFB71C1C),
                        unselectedLabelColor: Colors.grey,
                        tabs: widget.restaurant.menuCategories
                            .map((cat) => Tab(text: cat.name))
                            .toList(),
                      ),

                    const SizedBox(height: 10),

                    // ── Menu Items ───────────────────────────────────
                    Expanded(
                      child: widget.restaurant.menuCategories.isEmpty
                          ? const Center(
                              child: Text('No menu available',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : TabBarView(
                              controller: _tabController,
                              children: widget.restaurant.menuCategories
                                  .map((category) {
                                return category.menuItems.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No items in this category',
                                          style:
                                              TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.only(
                                            left: 20,
                                            right: 20,
                                            bottom: 100),
                                        itemCount:
                                            category.menuItems.length,
                                        itemBuilder: (context, index) {
                                          final item =
                                              category.menuItems[index];
                                          final isFav =
                                              _favouriteItems[item.id] ??
                                                  false;
                                          final inCart = cart.quantityOf(
                                              item.id);

                                          return _buildMenuItemCard(
                                              item, isFav, inCart, cart);
                                        },
                                      );
                              }).toList(),
                            ),
                    ),
                  ],
                ),

                // ── Floating Cart Button ─────────────────────────────
                if (widget.reservationId != null && cart.itemCount > 0)
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CartScreen(
                              restaurant: widget.restaurant,
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB71C1C).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${cart.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'View Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '${cart.total.toStringAsFixed(0)} RON',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItemCard(
      MenuItem item, bool isFav, int inCart, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: inCart > 0
            ? Border.all(color: const Color(0xFFB71C1C), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(15)),
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  )
                : _placeholderImage(),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${item.price.toStringAsFixed(0)} RON',
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Favourite + Cart controls
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color:
                        isFav ? const Color(0xFFB71C1C) : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => _toggleFavouriteItem(item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 6),
                if (widget.reservationId != null) ...[
                  if (inCart == 0)
                    GestureDetector(
                      onTap: () => _addToCart(item),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            cart.removeItem(item.id);
                            if (cart.orderId != null) {
                              // find orderItem id from backend sync is complex;
                              // we do a full re-sync approach: re-add via backend
                              // For simplicity, we rely on cart state locally
                              // and sync on CartScreen open
                            }
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.remove,
                                color: Colors.white, size: 16),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '$inCart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addToCart(item),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB71C1C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}