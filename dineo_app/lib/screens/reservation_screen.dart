import 'package:flutter/material.dart';
import '../models/restaurant.dart';

class ReservationScreen extends StatelessWidget {
  final Restaurant restaurant;
  final int userId;

  const ReservationScreen({
    super.key,
    required this.restaurant,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: Text(
            "Reservation coming soon",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}