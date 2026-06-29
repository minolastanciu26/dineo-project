import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import 'restaurant_detail_screen.dart';
import 'restaurants_category_screen.dart';

class RestaurantsScreen extends StatefulWidget {
  final String initialSearch;

  const RestaurantsScreen({super.key, this.initialSearch = ''});

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
    if (widget.initialSearch.isNotEmpty) {
      _searchController.text = widget.initialSearch;
    }
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final all = await _apiService.getRestaurants();
      final topRated = await _apiService.getTopRated();
      final newR = await _apiService.getNewRestaurants();

      List<Restaurant> nearest = [];
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition();
          nearest = List<Restaurant>.from(all)
            ..sort((a, b) {
              if (a.latitude == null || a.longitude == null) return 1;
              if (b.latitude == null || b.longitude == null) return -1;
              final da = Geolocator.distanceBetween(
                  pos.latitude, pos.longitude, a.latitude!, a.longitude!);
              final db = Geolocator.distanceBetween(
                  pos.latitude, pos.longitude, b.latitude!, b.longitude!);
              return da.compareTo(db);
            });
          nearest = nearest.take(10).toList();
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _allRestaurants = all;
        _topRated = topRated;
        _newRestaurants = newR;
        _nearest = nearest;
        _isLoading = false;
      });

      // Dacă avem search initial, facem search automat
      if (widget.initialSearch.isNotEmpty) {
        _search(widget.initialSearch);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Could not load restaurants.";
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final results = await _apiService.getRestaurants(search: query);
      if (!mounted) return;
      setState(() {
        _allRestaurants = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Search error.";
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
                  GestureDetector(
                    onTap: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: Image.asset('assets/images/logo.png', height: 30),
                  ),
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
                autofocus: widget.initialSearch.isNotEmpty,
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
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _loadRestaurants();
                          },
                        )
                      : null,
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
                      child: CircularProgressIndicator(
                          color: Color(0xFFB71C1C)),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.grey, size: 50),
                              const SizedBox(height: 10),
                              Text(_error!,
                                  style:
                                      const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loadRestaurants,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB71C1C),
                                ),
                                child: const Text("Retry",
                                    style:
                                        TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRestaurants,
                          color: const Color(0xFFB71C1C),
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            children: [
                              if (_searchController.text.isEmpty) ...[
                                // Popular
                                _buildSectionHeader(
                                    "Popular Restaurants", _topRated),
                                _buildHorizontalList(_topRated),
                                const SizedBox(height: 25),

                                // Nearest
                                _buildSectionHeader(
                                    "Nearest to You", _nearest),
                                _nearest.isEmpty
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.only(bottom: 25),
                                        child: SizedBox(
                                          height: 80,
                                          child: Center(
                                            child: Text(
                                              "Enable location to see nearby restaurants",
                                              style: TextStyle(
                                                  color: Colors.grey),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      )
                                    : _buildHorizontalList(_nearest),
                                const SizedBox(height: 25),

                                // New
                                _buildSectionHeader(
                                    "New on DINEO", _newRestaurants),
                                _buildHorizontalList(_newRestaurants),
                                const SizedBox(height: 25),

                                // All
                                _buildSectionHeader(
                                    "All Restaurants", _allRestaurants),
                                _buildHorizontalList(_allRestaurants),
                                const SizedBox(height: 20),
                              ] else ...[
                                if (_allRestaurants.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: Text(
                                        "No restaurants found",
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16),
                                      ),
                                    ),
                                  )
                                else
                                  ..._allRestaurants.map(
                                    (r) => _buildRestaurantCard(r,
                                        horizontal: false),
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

  Widget _buildSectionHeader(
      String title, List<Restaurant> restaurants) {
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
              style:
                  TextStyle(color: Color(0xFFB71C1C), fontSize: 14),
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
          child: Text("No restaurants yet",
              style: TextStyle(color: Colors.grey)),
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

  Widget _buildRestaurantCard(Restaurant restaurant,
      {required bool horizontal}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RestaurantDetailScreen(restaurant: restaurant),
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
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15)),
              child: restaurant.imageUrl != null
                  ? Image.network(
                      restaurant.imageUrl!,
                      height: horizontal ? 120 : 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildPlaceholder(horizontal),
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
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFB71C1C), size: 14),
                      const SizedBox(width: 3),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                      if (restaurant.cuisineType != null) ...[
                        const SizedBox(width: 6),
                        const Text("•",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 11)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            restaurant.cuisineType!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
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