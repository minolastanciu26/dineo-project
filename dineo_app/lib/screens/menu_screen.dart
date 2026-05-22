import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class MenuScreen extends StatefulWidget {
  final Restaurant restaurant;
  final int userId;

  const MenuScreen({super.key, required this.restaurant, required this.userId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  Map<int, bool> _favouriteItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.restaurant.menuCategories.length,
      vsync: this,
    );
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
  for (var category in widget.restaurant.menuCategories) {
    for (var item in category.menuItems) {
      if (!mounted) return;
      final isFav = await _apiService.checkFavouriteItem(widget.userId, item.id);
      if (mounted) {
        setState(() => _favouriteItems[item.id] = isFav);
      }
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
    } catch (e) {
      setState(() => _favouriteItems[item.id] = current);
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
                    child: Text(
                      widget.restaurant.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar categorii
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

            // Content
            Expanded(
              child: widget.restaurant.menuCategories.isEmpty
                  ? const Center(
                      child: Text("No menu available", style: TextStyle(color: Colors.grey)),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: widget.restaurant.menuCategories.map((category) {
                        return category.menuItems.isEmpty
                            ? const Center(
                                child: Text(
                                  "No items in this category",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: category.menuItems.length,
                                itemBuilder: (context, index) {
                                  final item = category.menuItems[index];
                                  final isFav = _favouriteItems[item.id] ?? false;

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
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Buton inimă
                                        Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: IconButton(
                                            icon: Icon(
                                              isFav ? Icons.favorite : Icons.favorite_border,
                                              color: isFav ? const Color(0xFFB71C1C) : Colors.grey,
                                            ),
                                            onPressed: () => _toggleFavouriteItem(item),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}