import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import 'restaurant_detail_screen.dart';

class FavouriteRestaurantsScreen extends StatefulWidget {
  final int userId;

  const FavouriteRestaurantsScreen({super.key, required this.userId});

  @override
  State<FavouriteRestaurantsScreen> createState() => _FavouriteRestaurantsScreenState();
}

class _FavouriteRestaurantsScreenState extends State<FavouriteRestaurantsScreen> {
  final ApiService _apiService = ApiService();
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    try {
      final restaurants = await _apiService.getFavouriteRestaurants(widget.userId);
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavourite(Restaurant restaurant) async {
    await _apiService.removeFavourite(widget.userId, restaurant.id);
    setState(() => _restaurants.removeWhere((r) => r.id == restaurant.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
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
                    "My Favourites",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                    )
                  : _restaurants.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.favorite_border, color: Colors.grey, size: 60),
                              const SizedBox(height: 15),
                              const Text(
                                "No favourite restaurants yet",
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Tap the heart on any restaurant to save it here",
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFavourites,
                          color: const Color(0xFFB71C1C),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _restaurants.length,
                            itemBuilder: (context, index) {
                              final restaurant = _restaurants[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantDetailScreen(
                                      restaurant: restaurant,
                                    ),
                                  ),
                                ).then((_) => _loadFavourites()),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      // Imagine
                                      ClipRRect(
                                        borderRadius: const BorderRadius.horizontal(
                                          left: Radius.circular(15),
                                        ),
                                        child: restaurant.imageUrl != null
                                            ? Image.network(
                                                restaurant.imageUrl!,
                                                width: 110,
                                                height: 110,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: 110,
                                                  height: 110,
                                                  color: const Color(0xFF2A2A2A),
                                                  child: const Icon(Icons.restaurant, color: Colors.grey),
                                                ),
                                              )
                                            : Container(
                                                width: 110,
                                                height: 110,
                                                color: const Color(0xFF2A2A2A),
                                                child: const Icon(Icons.restaurant, color: Colors.grey),
                                              ),
                                      ),

                                      // Info
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                restaurant.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (restaurant.address != null) ...[
                                                const SizedBox(height: 5),
                                                Text(
                                                  restaurant.address!,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star, color: Color(0xFFB71C1C), size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    restaurant.rating.toStringAsFixed(1),
                                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  ),
                                                  if (restaurant.cuisineType != null) ...[
                                                    const SizedBox(width: 8),
                                                    const Text("•", style: TextStyle(color: Colors.grey)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        restaurant.cuisineType!,
                                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Buton remove
                                      IconButton(
                                        icon: const Icon(Icons.favorite, color: Color(0xFFB71C1C)),
                                        onPressed: () => _removeFavourite(restaurant),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}