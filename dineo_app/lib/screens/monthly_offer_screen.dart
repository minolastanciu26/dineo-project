import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'restaurant_detail_screen.dart';
import '../models/restaurant.dart';

class MonthlyOfferScreen extends StatefulWidget {
  const MonthlyOfferScreen({super.key});

  @override
  State<MonthlyOfferScreen> createState() => _MonthlyOfferScreenState();
}

class _MonthlyOfferScreenState extends State<MonthlyOfferScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _userId = 0;
  Map<String, dynamic>? _offer;
  bool _isUsed = false;
  bool _isUsing = false;

  final List<String> _monthNames = [
    "", "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;

    try {
      final offer = await _apiService.getCurrentOffer();
      if (offer != null) {
        final status = await _apiService.getUserOfferStatus(_userId);
        if (mounted) {
          setState(() {
            _offer = offer;
            _isUsed = status?['isUsed'] ?? false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useOffer() async {
    setState(() => _isUsing = true);
    final success = await _apiService.useMonthlyOffer(_userId);
    if (success && mounted) {
      setState(() {
        _isUsed = true;
        _isUsing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 Offer activated! Enjoy your +1!"),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } else {
      if (mounted) setState(() => _isUsing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Image.asset('assets/images/logo.png', height: 30),
                  const SizedBox(width: 15),
                  const Text(
                    "Monthly Reward",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                ),
              )
            else if (_offer == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.card_giftcard, color: Colors.grey, size: 60),
                      SizedBox(height: 15),
                      Text(
                        "No offer this month",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Check back next month!",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Banner oferta
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8B0000),
                              Color(0xFFB71C1C),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "This Month's Reward",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _monthNames[
                                            _offer!['month'] as int],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "+1 FREE",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                "Bring a friend for free!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                "Make a reservation for 2+ people and one guest eats for free.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Restaurant card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagine restaurant
                            if (_offer!['restaurant']['imageUrl'] != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                child: Image.network(
                                  _offer!['restaurant']['imageUrl'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 200,
                                    color: const Color(0xFF2A2A2A),
                                    child: const Icon(Icons.restaurant,
                                        color: Colors.grey, size: 60),
                                  ),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _offer!['restaurant']['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB71C1C),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star,
                                                color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${_offer!['restaurant']['rating']}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  if (_offer!['restaurant']['cuisineType'] !=
                                      null)
                                    Text(
                                      _offer!['restaurant']['cuisineType'],
                                      style: const TextStyle(
                                          color: Color(0xFFB71C1C),
                                          fontSize: 14),
                                    ),
                                  const SizedBox(height: 8),

                                  if (_offer!['restaurant']['address'] != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            color: Colors.grey, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _offer!['restaurant']['address'],
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),

                                  if (_offer!['restaurant']['description'] !=
                                      null) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      _offer!['restaurant']['description'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 20),

                                  // Status oferta
                                  if (_isUsed)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A1E),
                                        borderRadius:
                                            BorderRadius.circular(15),
                                        border: Border.all(
                                            color: const Color(0xFF4CAF50)),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Color(0xFF4CAF50),
                                              size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            "Offer already used this month",
                                            style: TextStyle(
                                              color: Color(0xFF4CAF50),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isUsing ? null : _useOffer,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFB71C1C),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                        ),
                                        icon: _isUsing
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.card_giftcard,
                                                color: Colors.white),
                                        label: Text(
                                          _isUsing
                                              ? "Activating..."
                                              : "Use My +1 Offer",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          final r = _offer!['restaurant'];
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RestaurantDetailScreen(
                                                restaurant: Restaurant(
                                                  id: r['id'],
                                                  name: r['name'],
                                                  description: r['description'],
                                                  cuisineType: r['cuisineType'],
                                                  rating: (r['rating'] as num)
                                                      .toDouble(),
                                                  address: r['address'],
                                                  imageUrl: r['imageUrl'],
                                                  phoneNumber: r['phoneNumber'],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Color(0xFFB71C1C)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                        ),
                                        icon: const Icon(Icons.restaurant,
                                            color: Color(0xFFB71C1C)),
                                        label: const Text(
                                          "View Restaurant",
                                          style: TextStyle(
                                              color: Color(0xFFB71C1C),
                                              fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: const Color(0xFFB71C1C).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Color(0xFFB71C1C), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Each month a new restaurant is featured. Use your +1 offer once per month and discover new places!",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}