import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  String _result = '';

  void _getRecommendation() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final recommendation = await _apiService.getRecommendation(
        _controller.text.trim(),
      );
      setState(() {
        _isLoading = false;
        _result = recommendation;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = "Could not get recommendation. Please try again.";
      });
    }
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
            "Describe your mood, cuisine, occasion...",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Text input
          TextField(
            controller: _controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "e.g. something cozy for a date, Italian, not too expensive",
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

          // Button
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
          const SizedBox(height: 30),

          // Result
          if (_result.isNotEmpty)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB71C1C), width: 1),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
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
          'AI Recommender',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: content,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "What are you looking for this morning?";
    } else if (hour >= 12 && hour < 15) {
      return "What are you looking for lunch?";
    } else if (hour >= 15 && hour < 18) {
      return "What are you looking for this afternoon?";
    } else if (hour >= 18 && hour < 22) {
      return "What are you looking for tonight?";
    } else {
      return "What are you looking for?";
    }
  }
}