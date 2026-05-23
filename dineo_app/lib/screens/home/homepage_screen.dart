import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../widgets/ai_chat_button.dart';
import '../my_reservations_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _firstName = prefs.getString('firstName') ?? '';
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Where are you having breakfast?";
    } else if (hour >= 12 && hour < 15) {
      return "Where are you having lunch?";
    } else if (hour >= 15 && hour < 18) {
      return "Where are you going this afternoon?";
    } else if (hour >= 18 && hour < 22) {
      return "Where are you dining tonight?";
    } else {
      return "Looking for a late night spot?";
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, 0.2),
                  radius: 0.8,
                  colors: [Color(0xFF2A0A0A), Color(0xFF0F0F0F)],
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset("assets/images/logo.png", height: 28),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFB71C1C), width: 1.5),
                          color: const Color(0xFF1E1E1E),
                        ),
                        child: const Icon(Icons.person, color: Color(0xFFB71C1C), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _firstName.isEmpty ? "Hi there!" : "Hi, $_firstName!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGreeting(),
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 18),
                      const Icon(Icons.search, color: Color(0xFF666666), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Search restaurants",
                          style: TextStyle(color: Color(0xFF555555), fontSize: 14),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Filter",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final areaW = constraints.maxWidth;
                    final areaH = constraints.maxHeight;
                    final double R = areaW * 0.52;
                    final double arcR = R * 1.12;
                    final double cx = areaW * 0.02;
                    final double cy = areaH * 0.42;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: cx - R,
                          top: cy - R,
                          child: SizedBox(
                            width: R * 2,
                            height: R * 2,
                            child: Stack(
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    "assets/images/reward.png",
                                    width: R * 2,
                                    height: R * 2,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft,
                                        stops: const [0.35, 1.0],
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFF0F0F0F).withOpacity(0.95),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Positioned(
                          left: cx - arcR,
                          top: cy - arcR,
                          child: CustomPaint(
                            size: Size(arcR * 2, arcR * 2),
                            painter: _ArcPainter(radius: arcR),
                          ),
                        ),

                        ..._menuItems(context, cx, cy, arcR),

                        Positioned(
                          bottom: areaH * 0.04,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/map'),
                            child: const Column(
                              children: [
                                Text(
                                  "View the map",
                                  style: TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
                                ),
                                SizedBox(height: 2),
                                Icon(Icons.keyboard_arrow_down,
                                    color: Color(0xFFB71C1C), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          Positioned(
            bottom: size.height * 0.04,
            left: size.width * 0.06,
            child: const AiChatButton(),
          ),
        ],
      ),
    );
  }

  List<Widget> _menuItems(BuildContext context, double cx, double cy, double R) {
    final items = [
      {"label": "Restaurants", "route": "/restaurants", "angle": -52.0},
      {"label": "Map", "route": "/map", "angle": -18.0},
      {"label": "Calendar", "route": "/calendar", "angle": 16.0},
      {"label": "Profile", "route": "/profile", "angle": 50.0},
    ];

    return items.map((item) {
      final angle = (item["angle"] as double) * math.pi / 180;
      final dx = cx + R * math.cos(angle);
      final dy = cy + R * math.sin(angle);

      return Positioned(
        left: dx - 9,
        top: dy - 9,
        child: GestureDetector(
          onTap: () {
            if (item["label"] == "Calendar") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
              );
            } else {
              Navigator.pushNamed(context, item["route"] as String);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F0F0F),
                  border: Border.all(color: const Color(0xFFB71C1C), width: 2.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item["label"] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _ArcPainter extends CustomPainter {
  final double radius;
  const _ArcPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.72,
      math.pi * 1.44,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: const Center(child: Text("Harta")),
    );
  }
}