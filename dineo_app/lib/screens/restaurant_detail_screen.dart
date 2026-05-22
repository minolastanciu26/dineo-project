import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import 'menu_screen.dart';
import 'reservation_screen.dart';
import 'favourite_items_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isFavourite = false;
  bool _isLoading = false;
  int _userId = 0;
  Restaurant? _fullRestaurant;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;

    final isFav = await _apiService.checkFavourite(_userId, widget.restaurant.id);
    final full = await _apiService.getRestaurantById(widget.restaurant.id);

    if (mounted) {
      setState(() {
        _isFavourite = isFav;
        _fullRestaurant = full;
      });
    }
  }

  Future<void> _toggleFavourite() async {
    setState(() => _isLoading = true);
    try {
      if (_isFavourite) {
        await _apiService.removeFavourite(_userId, widget.restaurant.id);
      } else {
        await _apiService.addFavourite(_userId, widget.restaurant.id);
      }
      if (mounted) setState(() => _isFavourite = !_isFavourite);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error updating favourites")),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        _isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavourite ? const Color(0xFFB71C1C) : Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleFavourite,
                    ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: restaurant.imageUrl != null
                  ? Image.network(
                      restaurant.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.restaurant, color: Colors.grey, size: 60),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.restaurant, color: Colors.grey, size: 60),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nume + Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Cuisine type
                  if (restaurant.cuisineType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        restaurant.cuisineType!,
                        style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 15),

                  // Address
                  if (restaurant.address != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            restaurant.address!,
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Phone
                  if (restaurant.phoneNumber != null)
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          restaurant.phoneNumber!,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  const SizedBox(height: 25),

                  // Description
                  if (restaurant.description != null) ...[
                    const Text(
                      "About Us",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      restaurant.description!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // Menu preview
                  if (_fullRestaurant != null &&
                      _fullRestaurant!.menuCategories.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Menu Preview",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MenuScreen(
                                restaurant: _fullRestaurant!,
                                userId: _userId,
                              ),
                            ),
                          ),
                          child: const Text(
                            "See all",
                            style: TextStyle(color: Color(0xFFB71C1C), fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    ..._fullRestaurant!.menuCategories.first.menuItems
                        .take(3)
                        .map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.imageUrl != null
                                      ? Image.network(
                                          item.imageUrl!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 60,
                                            height: 60,
                                            color: const Color(0xFF2A2A2A),
                                            child: const Icon(Icons.fastfood, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: const Color(0xFF2A2A2A),
                                          child: const Icon(Icons.fastfood, color: Colors.grey),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (item.description != null)
                                        Text(
                                          item.description!,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${item.price.toStringAsFixed(0)} RON",
                                  style: const TextStyle(
                                    color: Color(0xFFB71C1C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: 25),
                  ],

                  // Butoane principale
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReservationScreen(
                            restaurant: widget.restaurant,
                            userId: _userId,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                      label: const Text(
                        "Reserve a Table",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _fullRestaurant == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MenuScreen(
                                    restaurant: _fullRestaurant!,
                                    userId: _userId,
                                  ),
                                ),
                              ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFB71C1C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book, color: Color(0xFFB71C1C), size: 18),
                      label: const Text(
                        "View Menu",
                        style: TextStyle(color: Color(0xFFB71C1C), fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FavouriteItemsScreen(
                            userId: _userId,
                            restaurantName: widget.restaurant.name,
                            restaurantId: widget.restaurant.id,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFB71C1C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: const Icon(Icons.favorite, color: Color(0xFFB71C1C), size: 18),
                      label: const Text(
                        "My Favourites",
                        style: TextStyle(color: Color(0xFFB71C1C), fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}