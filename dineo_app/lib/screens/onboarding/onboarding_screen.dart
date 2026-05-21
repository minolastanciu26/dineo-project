import 'package:flutter/material.dart';
import '../login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentIndex = 0;
  final List<Map<String, String>> pages = [
    {"title": "Pick Your Perfect Spot", "icon": "assets/images/pick your perfect spot.png"},
    {"title": "Unlock Monthly Rewards", "icon": "assets/images/unlock monthly rewards.png"},
    {"title": "Your Personal Taste Map", "icon": "assets/images/your personal taste map.png"},
    {"title": "Never Miss A Reservation", "icon": "assets/images/never miss a reservation.png"},
  ];

  void _nextPage() {
    if (currentIndex < pages.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      // Dacă este ultima pagină, mergem la Login
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = currentIndex == pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
              child: Image.asset("assets/images/welcome.png", fit: BoxFit.cover),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(pages[currentIndex]["icon"]!, height: 150),
                const SizedBox(height: 30),
                Text(
                  pages[currentIndex]["title"]!, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50, left: 30, right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), 
                  child: const Text("Skip", style: TextStyle(color: Colors.white, fontSize: 16))
                ),
                FloatingActionButton(
                  backgroundColor: const Color(0xFF990100), 
                  onPressed: _nextPage, 
                  child: Icon(isLastPage ? Icons.check : Icons.arrow_forward, color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}