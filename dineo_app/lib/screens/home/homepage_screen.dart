import 'package:flutter/material.dart';
import '../../widgets/circular_path_painter.dart';
import '../../widgets/circular_menu_clipper.dart'; 

class HomepageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Header: Logo DINEO + Profil
          Positioned(top: 60, left: 20, right: 20, child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset("assets/images/logo.png", height: 30),
              IconButton(icon: Icon(Icons.person, color: Colors.red), onPressed: () => Navigator.pushNamed(context, '/profile')),
            ],
          )),

          // Semicerc + Imagine decupată (Centrat Vertical)
          Center(
            child: Row(
              children: [
                ClipPath(
                  clipper: SemicircleClipper(), // Clipper-ul creat anterior
                  child: Image.asset("assets/images/reward.png", height: 350, width: 200, fit: BoxFit.cover),
                ),
                CustomPaint(size: Size(50, 350), painter: CircularPathPainter()),
              ],
            ),
          ),

          // Butoane (Restaurants, etc.)
          Positioned(top: 250, right: 30, child: _buildMenu()),

          // View the map (Jos)
          Positioned(bottom: 50, left: 0, right: 0, child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/map'),
            child: Column(children: [
              Text("View the map", style: TextStyle(color: Colors.red)),
              Icon(Icons.keyboard_arrow_down, color: Colors.red),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    final items = ["Restaurants", "Map", "Calendar", "Profile"];
    return Column(children: items.map((l) => Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(children: [Text(l, style: TextStyle(color: Colors.white)), SizedBox(width: 10), Container(width: 15, height: 15, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 2)))],),
    )).toList());
  }
}

class MapViewScreen extends StatelessWidget { 
  const MapViewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Map")), body: const Center(child: Text("Harta")));
  }
}