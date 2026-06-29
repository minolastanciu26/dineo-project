import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class DiscoveredScreen extends StatefulWidget {
  const DiscoveredScreen({super.key});

  @override
  State<DiscoveredScreen> createState() => _DiscoveredScreenState();
}

class _DiscoveredScreenState extends State<DiscoveredScreen> {
  final ApiService _apiService = ApiService();
  GoogleMapController? _mapController;
  bool _isLoading = true;
  int _userId = 0;

  List<dynamic> _allRestaurants = [];
  List<dynamic> _discoveredRestaurants = [];
  int _discoveredCount = 0;
  int _totalCount = 0;
  double _percentage = 0.0;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  static const LatLng _bucharestCenter = LatLng(44.4268, 26.0800);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;

    try {
      final data = await _apiService.getDiscovered(_userId);
      final all = data['allRestaurants'] as List;

      final Set<Marker> markers = {};
      final Set<Circle> circles = {};

      for (final r in all) {
        final lat = r['latitude'];
        final lng = r['longitude'];
        if (lat == null || lng == null) continue;

        final isDiscovered = r['isDiscovered'] == true;
        final pos = LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        );

        if (isDiscovered) {
          circles.add(Circle(
            circleId: CircleId('glow_${r['id']}'),
            center: pos,
            radius: 150,
            fillColor: const Color(0xFFB71C1C).withOpacity(0.2),
            strokeColor: Colors.transparent,
            strokeWidth: 0,
          ));
        }

        circles.add(Circle(
          circleId: CircleId('dot_${r['id']}'),
          center: pos,
          radius: 70,
          fillColor: isDiscovered
              ? const Color(0xFFB71C1C)
              : const Color(0xFF555555),
          strokeColor: isDiscovered
              ? Colors.white.withOpacity(0.8)
              : Colors.white.withOpacity(0.2),
          strokeWidth: 2,
        ));

        markers.add(Marker(
          markerId: MarkerId(r['id'].toString()),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          alpha: 0.0,
          infoWindow: InfoWindow(
            title: r['name'],
            snippet: isDiscovered ? '✅ Visited!' : 'Not yet visited',
          ),
        ));
      }

      if (mounted) {
        setState(() {
          _allRestaurants = all;
          _discoveredRestaurants =
              all.where((r) => r['isDiscovered'] == true).toList();
          _discoveredCount = data['discoveredCount'] as int;
          _totalCount = data['totalCount'] as int;
          _percentage = (data['percentage'] as num).toDouble();
          _markers = markers;
          _circles = circles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getBadge() {
    if (_discoveredCount >= 20) return '🏆 Explorer';
    if (_discoveredCount >= 10) return '🥇 Foodie';
    if (_discoveredCount >= 5) return '🥈 Regular';
    if (_discoveredCount >= 1) return '🥉 Beginner';
    return '🍽️ New Here';
  }

  String _getMotivation() {
    if (_discoveredCount == 0) return "Start exploring Bucharest's restaurants!";
    if (_percentage < 10) return "Great start! Keep exploring!";
    if (_percentage < 25) return "You're getting around! Keep it up!";
    if (_percentage < 50) return "Halfway there! Impressive!";
    if (_percentage < 75) return "Almost a true Bucharest foodie!";
    return "You've conquered Bucharest's food scene! 🎉";
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
                  GestureDetector(
                    onTap: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: Image.asset('assets/images/logo.png', height: 30),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Discovered",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                ),
              )
            else
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Stats card
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _getBadge(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: CircularProgressIndicator(
                                    value: _percentage / 100,
                                    strokeWidth: 10,
                                    backgroundColor: const Color(0xFF2A2A2A),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFB71C1C),
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "${_percentage.toStringAsFixed(0)}%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "$_discoveredCount/$_totalCount",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _getMotivation(),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMilestone(1, "First"),
                                _buildMilestone(5, "5"),
                                _buildMilestone(10, "10"),
                                _buildMilestone(20, "20"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Harta
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 300,
                            child: GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: _bucharestCenter,
                                zoom: 12.5,
                              ),
                              markers: _markers,
                              circles: _circles,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                _mapController!
                                    .setMapStyle(_minimalDarkStyle);
                              },
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: true,
                              scrollGesturesEnabled: true,
                              zoomGesturesEnabled: true,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              gestureRecognizers: {
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Legenda
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB71C1C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text("Visited",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: 20),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF555555),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text("Not yet",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),

                    // Lista restaurante
                    if (_discoveredRestaurants.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                          child: Text(
                            "Places you've visited",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final r = _discoveredRestaurants[index];
                            return Container(
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        const BorderRadius.horizontal(
                                      left: Radius.circular(15),
                                    ),
                                    child: r['imageUrl'] != null
                                        ? Image.network(
                                            r['imageUrl'],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              width: 80,
                                              height: 80,
                                              color: const Color(0xFF2A2A2A),
                                              child: const Icon(
                                                  Icons.restaurant,
                                                  color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            width: 80,
                                            height: 80,
                                            color: const Color(0xFF2A2A2A),
                                            child: const Icon(
                                                Icons.restaurant,
                                                color: Colors.grey),
                                          ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r['name'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (r['cuisineType'] != null) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              r['cuisineType'],
                                              style: const TextStyle(
                                                color: Color(0xFFB71C1C),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                          if (r['address'] != null) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              r['address'],
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(Icons.check_circle,
                                        color: Color(0xFFB71C1C), size: 24),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: _discoveredRestaurants.length,
                        ),
                      ),
                    ] else ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Column(
                            children: [
                              Icon(Icons.explore_outlined,
                                  color: Colors.grey, size: 60),
                              SizedBox(height: 15),
                              Text(
                                "No restaurants discovered yet",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Make a reservation and visit a restaurant\nto start your discovery journey!",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestone(int target, String label) {
    final achieved = _discoveredCount >= target;
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: achieved
                ? const Color(0xFFB71C1C)
                : const Color(0xFF2A2A2A),
            border: Border.all(
              color: achieved
                  ? const Color(0xFFB71C1C)
                  : const Color(0xFF3A3A3A),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: achieved ? Colors.white : Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          achieved ? Icons.check : Icons.lock_outline,
          color: achieved ? const Color(0xFFB71C1C) : Colors.grey,
          size: 14,
        ),
      ],
    );
  }
}

const String _minimalDarkStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1a1a2e"}]},
  {"elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#3a3a5c"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2c2c44"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3a3a5c"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0d1b2a"}]},
  {"featureType": "landscape", "elementType": "geometry", "stylers": [{"color": "#1e1e30"}]}
]
''';