import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/restaurant.dart';
import 'restaurant_detail_screen.dart';

class RecommendScreen extends StatefulWidget {
  final bool isEmbedded;
  const RecommendScreen({super.key, this.isEmbedded = false});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _intro = '';
  List<Map<String, dynamic>> _results = [];
  String _error = '';

  void _getRecommendation() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _intro = '';
      _results = [];
      _error = '';
    });

    try {
      final data = await _apiService.getRecommendation(_controller.text.trim());
      setState(() {
        _isLoading = false;
        _intro = data['intro'] ?? '';
        _results = List<Map<String, dynamic>>.from(data['results'] ?? []);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Could not get recommendations. Please try again.";
      });
    }
  }

  void _openRestaurant(Map<String, dynamic> r) {
    final restaurant = Restaurant(
      id: r['id'] as int,
      name: r['name'] as String? ?? '',
      rating: (r['rating'] as num).toDouble(),
      cuisineType: r['cuisineType'] as String?,
      imageUrl: r['imageUrl'] as String?,
      description: r['description'] as String?,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: restaurant)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Describe what you're looking for: cuisine, occasion, atmosphere...",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "e.g. romantic Italian, cheap sushi, night out with friends...",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF333333),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _getRecommendation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Find my restaurant",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          if (_error.isNotEmpty)
            Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),

          if (_intro.isNotEmpty) ...[
            Text(
              _intro,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _RestaurantCard(
                  data: _results[i],
                  onTap: () => _openRestaurant(_results[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.isEmbedded) return content;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DINEO Recommendations',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: content,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "What are you looking for this morning?";
    if (hour >= 12 && hour < 15) return "What are you looking for lunch?";
    if (hour >= 15 && hour < 18) return "What are you looking for this afternoon?";
    if (hour >= 18 && hour < 22) return "What are you looking for tonight?";
    return "What restaurant are you looking for?";
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _RestaurantCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final reasonText = data['reasonText'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB71C1C), width: 1),
        ),
        child: Row(
          children: [
            // Image or placeholder
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.amber, fontSize: 13),
                        ),
                      ],
                    ),
                    if (reasonText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reasonText,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.white38, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 90,
        height: 90,
        color: const Color(0xFF3A1A1A),
        child: const Icon(Icons.restaurant, color: Colors.white24, size: 32),
      );
}
