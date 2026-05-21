import 'package:flutter/material.dart';

class CircularMenu extends StatelessWidget {
  const CircularMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 400,
      child: Stack(
        children: [
          // Linia semicerc (poți folosi un CustomPainter pentru perfecțiune)
          Positioned(right: 0, top: 0, bottom: 0, child: Container(width: 2, color: Colors.grey)),
          
          // Butoanele
          _buildMenuItem(top: 50, label: "Restaurants"),
          _buildMenuItem(top: 150, label: "Map"),
          _buildMenuItem(top: 250, label: "Calendar"),
          _buildMenuItem(top: 350, label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required double top, required String label}) {
    return Positioned(
      top: top, right: -15,
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 10),
          Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 3))),
        ],
      ),
    );
  }
}