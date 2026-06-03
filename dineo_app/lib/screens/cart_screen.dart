import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  final Restaurant restaurant;
  final int userId;

  const CartScreen({
    super.key,
    required this.restaurant,
    required this.userId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  bool _syncing = false;

  // Sync the full cart to backend (used on quantity changes)
  Future<void> _syncCartToBackend() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.orderId == null) return;

    setState(() => _syncing = true);

    try {
      // Get current items on backend
      final orderData =
          await _apiService.getOrderByReservation(cart.reservationId!);
      if (orderData == null) return;

      final backendItems =
          List<Map<String, dynamic>>.from(orderData['items'] ?? []);

      // For each item in local cart → ensure backend matches
      for (final cartItem in cart.items) {
        final backendItem = backendItems.firstWhere(
          (bi) => bi['menuItemId'] == cartItem.menuItemId,
          orElse: () => {},
        );

        if (backendItem.isEmpty) {
          // Add new item
          await _apiService.addItemToOrder(
            orderId: cart.orderId!,
            menuItemId: cartItem.menuItemId,
            quantity: cartItem.quantity,
          );
        } else {
          // Update quantity
          await _apiService.updateOrderItem(
            orderId: cart.orderId!,
            itemId: backendItem['id'],
            quantity: cartItem.quantity,
          );
        }
      }

      // Remove items that are in backend but not in local cart
      for (final backendItem in backendItems) {
        final inCart = cart.items
            .any((ci) => ci.menuItemId == backendItem['menuItemId']);
        if (!inCart) {
          await _apiService.removeOrderItem(
            orderId: cart.orderId!,
            itemId: backendItem['id'],
          );
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────
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
                      const Expanded(
                        child: Text(
                          'Your Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_syncing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFFB71C1C),
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),

                if (cart.items.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              color: Colors.grey, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add items from the menu to start your order',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // ── Restaurant name chip ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant,
                            color: Color(0xFFB71C1C), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          cart.restaurantName ?? widget.restaurant.name,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // ── Items list ───────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return _buildCartItem(context, item, cart);
                      },
                    ),
                  ),

                  // ── Summary & CTA ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 15),
                            ),
                            Text(
                              '${cart.total.toStringAsFixed(0)} RON',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                            color: Color(0xFF2A2A2A), height: 24),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${cart.total.toStringAsFixed(0)} RON',
                              style: const TextStyle(
                                color: Color(0xFFB71C1C),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Sync then go to payment
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.payment,
                                color: Colors.white),
                            label: const Text(
                              'Request Bill',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB71C1C),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              await _syncCartToBackend();
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(
                                    orderId: cart.orderId!,
                                    restaurantName: cart.restaurantName ??
                                        widget.restaurant.name,
                                    total: cart.total,
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartItem(
      BuildContext context, CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),

          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} RON each',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              _qtyButton(
                icon: Icons.remove,
                onTap: () => cart.removeItem(item.menuItemId),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              _qtyButton(
                icon: Icons.add,
                onTap: () => cart.addItem(
                  menuItemId: item.menuItemId,
                  name: item.name,
                  price: item.price,
                  imageUrl: item.imageUrl,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Subtotal
          Text(
            '${(item.price * item.quantity).toStringAsFixed(0)} RON',
            style: const TextStyle(
              color: Color(0xFFB71C1C),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 24),
    );
  }
}