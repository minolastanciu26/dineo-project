import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReviewsScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;
  final int userId;

  const ReviewsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.userId,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _apiService.getReviews(widget.restaurantId);
      final ratingData = await _apiService.getAverageRating(widget.restaurantId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = (ratingData['average'] as num).toDouble();
          _reviewCount = ratingData['count'] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openWriteReview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(
        restaurantId: widget.restaurantId,
        userId: widget.userId,
        onReviewSubmitted: () {
          _loadReviews();
        },
      ),
    );
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
                      widget.restaurantName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _openWriteReview,
                    child: const Text(
                      "Write a review",
                      style: TextStyle(color: Color(0xFFB71C1C), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Average rating
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStars(_averageRating, size: 24),
                      const SizedBox(height: 5),
                      Text(
                        "$_reviewCount reviews",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Reviews list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                    )
                  : _reviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rate_review_outlined,
                                  color: Colors.grey, size: 60),
                              const SizedBox(height: 15),
                              const Text(
                                "No reviews yet",
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _openWriteReview,
                                child: const Text(
                                  "Be the first to write a review!",
                                  style: TextStyle(color: Color(0xFFB71C1C)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReviews,
                          color: const Color(0xFFB71C1C),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              final user = review['user'];
                              final firstName = user?['firstName'] ?? '';
                              final lastName = user?['lastName'] ?? '';
                              final fullName = '$firstName $lastName'.trim();
                              final rating = (review['rating'] as num).toDouble();
                              final comment = review['comment'] ?? '';
                              final date = DateTime.parse(review['createdAt']);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Avatar
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: const Color(0xFF332020),
                                          child: Text(
                                            firstName.isNotEmpty
                                                ? firstName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Color(0xFFB71C1C),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fullName.isEmpty ? 'Anonymous' : fullName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                "${date.day}/${date.month}/${date.year}",
                                                style: const TextStyle(
                                                    color: Colors.grey, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildStars(rating, size: 16),
                                      ],
                                    ),
                                    if (comment.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        comment,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ],
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

  Widget _buildStars(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: const Color(0xFFB71C1C), size: size);
        } else if (index < rating && rating - index >= 0.5) {
          return Icon(Icons.star_half, color: const Color(0xFFB71C1C), size: size);
        } else {
          return Icon(Icons.star_border, color: const Color(0xFFB71C1C), size: size);
        }
      }),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  final int restaurantId;
  final int userId;
  final VoidCallback onReviewSubmitted;

  const _WriteReviewSheet({
    required this.restaurantId,
    required this.userId,
    required this.onReviewSubmitted,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _apiService.createReview(
      userId: widget.userId,
      restaurantId: widget.restaurantId,
      rating: _selectedRating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) Navigator.pop(context);
      widget.onReviewSubmitted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Review submitted!"),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to submit review. Try again."),
            backgroundColor: Color(0xFFB71C1C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Write a Review",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),

          // Star rating selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = index + 1),
                child: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFB71C1C),
                  size: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 25),

          // Comment field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _commentController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Share your experience...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF333333),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Submit button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Review",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}