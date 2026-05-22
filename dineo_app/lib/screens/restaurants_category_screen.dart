import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import 'restaurant_detail_screen.dart';

class RestaurantsCategoryScreen extends StatelessWidget {
  final String title;
  final List<Restaurant> restaurants;

  const RestaurantsCategoryScreen({
    super.key,
    required this.title,
    required this.restaurants,
  });

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
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Lista
            Expanded(
              child: restaurants.isEmpty
                  ? const Center(
                      child: Text(
                        "No restaurants in this category yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final r = restaurants[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantDetailScreen(restaurant: r),
                            ),
                          ),
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
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                                  child: r.imageUrl != null
                                      ? Image.network(
                                          r.imageUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 100,
                                            height: 100,
                                            color: const Color(0xFF2A2A2A),
                                            child: const Icon(Icons.restaurant, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          width: 100,
                                          height: 100,
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
                                          r.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (r.address != null) ...[
                                          const SizedBox(height: 5),
                                          Text(
                                            r.address!,
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                                              r.rating.toStringAsFixed(1),
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                            if (r.cuisineType != null) ...[
                                              const SizedBox(width: 8),
                                              const Text("•", style: TextStyle(color: Colors.grey)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  r.cuisineType!,
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
                                const Icon(Icons.chevron_right, color: Color(0xFFB71C1C)),
                                const SizedBox(width: 10),
                              ],
                            ),
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