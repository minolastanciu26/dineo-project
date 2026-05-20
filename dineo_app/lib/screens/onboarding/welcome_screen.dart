import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen())),
      child: Scaffold(
        body: Stack(
          children: [
            // Imagine pe tot ecranul
            Positioned.fill(
              child: Image.asset("assets/images/welcome.png", fit: BoxFit.cover),
            ),
            // Centrarea logo-ului
            Center(
              child: Image.asset("assets/images/logo.png", height: 100),
            ),
            // Text la baza ecranului
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 50.0),
                child: Text("Tap to explore DINEO's world", style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}