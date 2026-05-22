import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import 'restaurant_detail_screen.dart';
import 'restaurants_category_screen.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _topRated = [];
  List<Restaurant> _newRestaurants = [];
  List<Restaurant> _nearest = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<Position?> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  List<Restaurant> _sortByNearest(List<Restaurant> restaurants, Position userPos) {
    final withLocation = restaurants
        .where((r) => r.latitude != null && r.longitude != null)
        .toList();

    withLocation.sort((a, b) {
      final distA = Geolocator.distanceBetween(
        userPos.latitude, userPos.longitude,
        a.latitude!, a.longitude!,
      );
      final distB = Geolocator.distanceBetween(
        userPos.latitude, userPos.longitude,
        b.latitude!, b.longitude!,
      );
      return distA.compareTo(distB);
    });

    return withLocation;
  }

  Future<void> _loadRestaurants() async {
    try {
      setState(() => _isLoading = true);

      final all = await _apiService.getRestaurants();
      final top = await _apiService.getTopRated();
      final newR = await _apiService.getNewRestaurants();

      List<Restaurant> nearest = [];
      final position = await _getUserLocation();
      if (position != null) {
        nearest = _sortByNearest(all, position);
      }

      setState(() {
        _allRestaurants = all;
        _topRated = top;
        _newRestaurants = newR;
        _nearest = nearest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Nu mă pot conecta la server.";
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    try {
      setState(() => _isLoading = true);
      final results = await _apiService.getRestaurants(search: query);
      setState(() {
        _allRestaurants = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Eroare la căutare.";
        _isLoading = false;
      });
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
                  Image.asset('assets/images/logo.png', height: 30),
                  const Spacer(),
                  const Text(
                    "Restaurants",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  if (val.isEmpty) {
                    _loadRestaurants();
                  } else {
                    _search(val);
                  }
                },
                decoration: InputDecoration(
                  hintText: "Search restaurants...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.grey, size: 50),
                              const SizedBox(height: 10),
                              Text(_error!, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loadRestaurants,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB71C1C),
                                ),
                                child: const Text("Retry", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRestaurants,
                          color: const Color(0xFFB71C1C),
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              if (_searchController.text.isEmpty) ...[
                                // Popular
                                _buildSectionHeader("Popular Restaurants", _topRated),
                                _buildHorizontalList(_topRated),
                                const SizedBox(height: 25),

                                // Nearest
                                _buildSectionHeader("Nearest to You", _nearest),
                                _nearest.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.only(bottom: 25),
                                        child: SizedBox(
                                          height: 80,
                                          child: Center(
                                            child: Text(
                                              "Enable location to see nearby restaurants",
                                              style: TextStyle(color: Colors.grey),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      )
                                    : _buildHorizontalList(_nearest),
                                const SizedBox(height: 25),

                                // New
                                _buildSectionHeader("New on DINEO", _newRestaurants),
                                _buildHorizontalList(_newRestaurants),
                                const SizedBox(height: 25),

                                // All
                                _buildSectionHeader("All Restaurants", _allRestaurants),
                                _buildHorizontalList(_allRestaurants),
                                const SizedBox(height: 20),
                              ] else ...[
                                // Search results
                                ..._allRestaurants.map(
                                  (r) => _buildRestaurantCard(r, horizontal: false),
                                ),
                              ],
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

  Widget _buildSectionHeader(String title, List<Restaurant> restaurants) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantsCategoryScreen(
                  title: title,
                  restaurants: restaurants,
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
    );
  }

  Widget _buildHorizontalList(List<Restaurant> restaurants) {
    if (restaurants.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text("No restaurants yet", style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: restaurants.length,
        itemBuilder: (context, index) => _buildRestaurantCard(
          restaurants[index],
          horizontal: true,
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, {required bool horizontal}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
        ),
      ),
      child: Container(
        width: horizontal ? 200 : double.infinity,
        margin: horizontal
            ? const EdgeInsets.only(right: 15)
            : const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: restaurant.imageUrl != null
                  ? Image.network(
                      restaurant.imageUrl!,
                      height: horizontal ? 120 : 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(horizontal),
                    )
                  : _buildPlaceholder(horizontal),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (restaurant.address != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      restaurant.address!,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFB71C1C), size: 14),
                      const SizedBox(width: 3),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      if (restaurant.cuisineType != null) ...[
                        const SizedBox(width: 6),
                        const Text("•", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            restaurant.cuisineType!,
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool horizontal) {
    return Container(
      height: horizontal ? 120 : 150,
      width: double.infinity,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.restaurant, color: Colors.grey, size: 40),
    );
  }
}