import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../widgets/ai_chat_button.dart';
import '../../widgets/order_progress_card.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../my_reservations_screen.dart';
import '../monthly_offer_screen.dart';
import '../restaurants_screen.dart';
import '../notifications_screen.dart';
import '../map_screen.dart';
import '../profile_screen.dart';
import '../menu_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  final ApiService _apiService = ApiService();
  String _firstName = '';
  int _userId = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _firstName = prefs.getString('firstName') ?? '';
        _userId = prefs.getInt('userId') ?? 0;
      });
    }
    if (_userId > 0) {
      _apiService.checkReservationArrivals(_userId);
      await _loadActiveOrder();
      _startOrderStatusPolling();
    }
  }

  Future<void> _loadActiveOrder() async {
    try {
      final orderData = await _apiService.getActiveOrderForUser(_userId);
      if (orderData == null || !mounted) return;
      final cart = Provider.of<CartProvider>(context, listen: false);
      if (cart.orderId != null) return;
      cart.setContext(
        orderId: orderData['id'],
        reservationId: orderData['reservationId'] ?? 0,
        restaurantId: orderData['restaurantId'],
        restaurantName: orderData['restaurantName'] ?? '',
        status: orderData['status'] ?? 'Pending',
      );
      final items = orderData['items'] as List? ?? [];
      for (final item in items) {
        final qty = item['quantity'] as int? ?? 1;
        for (int i = 0; i < qty; i++) {
          cart.addItem(
            menuItemId: item['menuItemId'],
            name: item['menuItemName'] ?? '',
            price: (item['price'] as num).toDouble(),
          );
        }
      }
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12)  return "Where are you having breakfast?";
    if (hour >= 12 && hour < 15) return "Where are you having lunch?";
    if (hour >= 15 && hour < 18) return "Where are you going this afternoon?";
    if (hour >= 18 && hour < 22) return "Where are you dining tonight?";
    return "Looking for a late night spot?";
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => RestaurantsScreen(initialSearch: query.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Gradient background (no red circle) ──────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: const Color(0xFF0F0F0F),
              ),
            ),
          ),

          // ── Scrollable body ───────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                final bool hasOrder = cart.orderId != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // Logo + icons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset("assets/images/logo.png", height: 28),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => const NotificationsScreen())),
                                child: Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFB71C1C), width: 1.5),
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                  child: const Icon(Icons.notifications_outlined,
                                      color: Color(0xFFB71C1C), size: 20),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/profile'),
                                child: Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFB71C1C), width: 1.5),
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                  child: const Icon(Icons.person,
                                      color: Color(0xFFB71C1C), size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Greeting
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _firstName.isEmpty ? "Hi there!" : "Hi, $_firstName!",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_getGreeting(),
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 18),
                            const Icon(Icons.search,
                                color: Color(0xFF666666), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: "Search restaurants",
                                  hintStyle:
                                      TextStyle(color: Color(0xFF555555)),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onSubmitted: _onSearch,
                                textInputAction: TextInputAction.search,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Order card — animat, apare/dispare
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: hasOrder
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OrderProgressCard(
                                onAddMore: () async {
                                  if (cart.restaurantId == null) return;
                                  final restaurant = await _apiService
                                      .getRestaurantById(cart.restaurantId!);
                                  if (restaurant == null || !mounted) return;
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => MenuScreen(
                                      restaurant: restaurant,
                                      userId: _userId,
                                      reservationId: cart.reservationId,
                                    ),
                                  ));
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 28),

                    // ── Circular menu area ─────────────────────────────
                    // Uses LayoutBuilder inside a fixed-ratio container
                    // so it always looks the same regardless of card presence
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double areaW = size.width;
                        final double areaH = size.height * 0.68;
                        final double R    = areaW * 0.52;
                        final double arcR = R * 1.12;
                        final double cx   = areaW * 0.02;
                        final double cy   = areaH * 0.44;

                        final items = [
                          {"label": "Restaurants", "route": "/restaurants", "angle": -52.0},
                          {"label": "Map",         "route": "/map",         "angle": -18.0},
                          {"label": "Calendar",    "route": "/calendar",    "angle":  16.0},
                          {"label": "Profile",     "route": "/profile",     "angle":  50.0},
                        ];

                        return SizedBox(
                          width: areaW,
                          height: areaH,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Circular image
                              Positioned(
                                left: cx - R,
                                top: cy - R,
                                child: SizedBox(
                                  width: R * 2,
                                  height: R * 2,
                                  child: Stack(
                                    children: [
                                      ClipOval(
                                        child: Image.asset(
                                          "assets/images/reward.png",
                                          width: R * 2,
                                          height: R * 2,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.centerRight,
                                              end: Alignment.centerLeft,
                                              stops: const [0.35, 1.0],
                                              colors: [
                                                Colors.transparent,
                                                const Color(0xFF0F0F0F)
                                                    .withValues(alpha: 0.95),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Arc decorativ
                              Positioned(
                                left: cx - arcR,
                                top: cy - arcR,
                                child: CustomPaint(
                                  size: Size(arcR * 2, arcR * 2),
                                  painter: _ArcPainter(radius: arcR),
                                ),
                              ),

                              // Menu items
                              ...items.map((item) {
                                final angle =
                                    (item["angle"] as double) * math.pi / 180;
                                final dx = cx + arcR * math.cos(angle);
                                final dy = cy + arcR * math.sin(angle);
                                return Positioned(
                                  left: dx - 9,
                                  top: dy - 9,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (item["label"] == "Calendar") {
                                        Navigator.push(context,
                                          MaterialPageRoute(builder: (_) =>
                                              const MyReservationsScreen()));
                                      } else if (item["label"] == "Restaurants") {
                                        Navigator.push(context,
                                          MaterialPageRoute(builder: (_) =>
                                              const RestaurantsScreen()));
                                      } else if (item["label"] == "Map") {
                                        Navigator.push(context,
                                          MaterialPageRoute(builder: (_) =>
                                              const MapScreen()));
                                      } else if (item["label"] == "Profile") {
                                        Navigator.push(context,
                                          MaterialPageRoute(builder: (_) =>
                                              const ProfileScreen()));
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 18, height: 18,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF0F0F0F),
                                            border: Border.all(
                                                color: const Color(0xFFB71C1C),
                                                width: 2.5),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          item["label"] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              // Gift button
                              Positioned(
                                left: cx + R * 0.15,
                                top: cy - R * 0.25,
                                child: _PulseGiftButton(
                                  onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                        const MonthlyOfferScreen())),
                                ),
                              ),

                              // View the map
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () =>
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                                  child: const Column(
                                    children: [
                                      Text("View the map",
                                        style: TextStyle(
                                            color: Color(0xFFB71C1C),
                                            fontSize: 13)),
                                      SizedBox(height: 2),
                                      Icon(Icons.keyboard_arrow_down,
                                          color: Color(0xFFB71C1C), size: 18),
                                    ],
                                  ),
                                ),
                              ),
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

          // AI button — mereu vizibil, deasupra scroll
          Positioned(
            bottom: size.height * 0.04,
            right: size.width * 0.06,
            child: const AiChatButton(),
          ),
        ],
      ),
    );
  }
}

// ── Animated gift button ──────────────────────────────────────────────────

class _PulseGiftButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PulseGiftButton({required this.onTap});
  @override
  State<_PulseGiftButton> createState() => _PulseGiftButtonState();
}

class _PulseGiftButtonState extends State<_PulseGiftButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }


  // Poll order status every 10 seconds — updates card and clears cart when Paid
  void _startOrderStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final cart = Provider.of<CartProvider>(context, listen: false);
      if (cart.orderId == null) {
        _statusTimer?.cancel();
        return;
      }
      try {
        final orderData = await _apiService.getActiveOrderForUser(_userId);
        if (!mounted) return;

        if (orderData == null) {
          // Order is now Paid/Cancelled — clear cart and prompt review
          final oldRestaurantId = cart.restaurantId;
          final oldRestaurantName = cart.restaurantName;
          cart.clearCart();
          _statusTimer?.cancel();

          // Show review prompt
          if (mounted && oldRestaurantId != null) {
            _showReviewPrompt(oldRestaurantId, oldRestaurantName ?? '');
          }
          return;
        }

        final newStatus = orderData['status'] as String? ?? 'Pending';
        if (newStatus != cart.orderStatus) {
          cart.updateStatus(newStatus);

          // If just marked Paid
          if (newStatus == 'Paid') {
            final restId = cart.restaurantId;
            final restName = cart.restaurantName ?? '';
            cart.clearCart();
            _statusTimer?.cancel();
            if (mounted) _showReviewPrompt(restId!, restName);
          }
        }
      } catch (_) {}
    });
  }

  void _showReviewPrompt(int restaurantId, String restaurantName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '⭐ How was your meal?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Leave a review for $restaurantName and help others discover it!',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/restaurant/$restaurantId/review');
            },
            child: const Text('Leave Review',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Transform.scale(
          scale: _pulse.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(width: 70, height: 70),
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFFB71C1C)),
                child: const Icon(Icons.card_giftcard,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Arc painter ───────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double radius;
  const _ArcPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.72,
      math.pi * 1.44,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: const Center(child: Text("Harta")),
    );
  }
}