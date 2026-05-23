import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class FavouriteItemsScreen extends StatefulWidget {
  final int userId;
  final String restaurantName;
  final int restaurantId;

  const FavouriteItemsScreen({
    super.key,
    required this.userId,
    required this.restaurantName,
    required this.restaurantId,
  });

  @override
  State<FavouriteItemsScreen> createState() => _FavouriteItemsScreenState();
}

class _FavouriteItemsScreenState extends State<FavouriteItemsScreen> {
  final ApiService _apiService = ApiService();
  List<MenuItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavouriteItems();
  }

  Future<void> _loadFavouriteItems() async {
    try {
      final items = await _apiService.getFavouriteItemsByRestaurant(
        widget.userId,
        widget.restaurantId,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavouriteItem(MenuItem item) async {
    await _apiService.removeFavouriteItem(widget.userId, item.id);
    if (mounted) {
      setState(() => _items.removeWhere((i) => i.id == item.id));
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "My Favourite Dishes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.restaurantName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
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
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.favorite_border, color: Colors.grey, size: 60),
                              const SizedBox(height: 15),
                              const Text(
                                "No favourite dishes yet",
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Tap the heart on any dish to save it here",
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Container(
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
                                    child: item.imageUrl != null
                                        ? Image.network(
                                            item.imageUrl!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 100,
                                              height: 100,
                                              color: const Color(0xFF2A2A2A),
                                              child: const Icon(Icons.fastfood, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            color: const Color(0xFF2A2A2A),
                                            child: const Icon(Icons.fastfood, color: Colors.grey),
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
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 8),
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

                                  // Buton remove
                                  IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: Color(0xFFB71C1C),
                                    ),
                                    onPressed: () => _removeFavouriteItem(item),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}