import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  double _currentZoom = 13.5;

  final List<Map<String, dynamic>> _restaurants = [
    {
      "id": 1,
      "name": "La Grande Bellezza",
      "cuisineType": "Italian",
      "rating": 4.8,
      "description": "Don Stefano loves life. For him, life is a combination of amore, good food, the coldest drinks and the best company. This is la grande bellezza della vita.",
      "lat": 44.4396,
      "lng": 26.0963,
    },
    {
      "id": 2,
      "name": "Caru' cu Bere",
      "cuisineType": "Romanian",
      "rating": 4.6,
      "description": "A historic brewery restaurant in the heart of Bucharest, famous for its stunning neo-gothic architecture and traditional Romanian cuisine since 1879.",
      "lat": 44.4309,
      "lng": 26.0979,
    },
    {
      "id": 3,
      "name": "Vatra",
      "cuisineType": "Romanian",
      "rating": 4.5,
      "description": "A cozy hearth-inspired restaurant serving traditional Romanian dishes with a modern twist. Perfect for family gatherings and romantic evenings alike.",
      "lat": 44.4478,
      "lng": 26.0800,
    },
    {
      "id": 4,
      "name": "Shift",
      "cuisineType": "International",
      "rating": 4.3,
      "description": "A vibrant international fusion restaurant where culinary traditions from around the world meet. Creative cocktails and an ever-changing seasonal menu.",
      "lat": 44.4412,
      "lng": 26.1020,
    },
    {
      "id": 5,
      "name": "Lacrimi si Sfinti",
      "cuisineType": "Romanian Fusion",
      "rating": 4.7,
      "description": "An avant-garde Romanian fusion restaurant pushing the boundaries of local cuisine. Chef Joseph Hadad reimagines classic dishes with international techniques.",
      "lat": 44.4350,
      "lng": 26.0890,
    },
  ];

  Map<String, dynamic>? _selectedRestaurant;
  Set<Marker> _markers = {};

  static const LatLng _bucharestCenter = LatLng(44.4396, 26.0963);
  static const double _labelZoomThreshold = 15.5;

  // Draggable sheet controller
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Snap sizes as fraction of screen height
  static const double _collapsedSize = 0.22;
  static const double _expandedSize = 0.32;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _buildMarkers() {
    final bool showLabels = _currentZoom >= _labelZoomThreshold;

    final markers = _restaurants.map((r) {
      return Marker(
        markerId: MarkerId(r["id"].toString()),
        position: LatLng(r["lat"], r["lng"]),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: showLabels
            ? InfoWindow(title: r["name"], snippet: r["cuisineType"])
            : InfoWindow.noText,
        alpha: showLabels ? 0.0 : 1.0,
        onTap: () {
          setState(() {
            _selectedRestaurant = r;
          });
        },
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
  }

  void _onCameraMove(CameraPosition position) {
    final newZoom = position.zoom;
    if ((newZoom >= _labelZoomThreshold) !=
        (_currentZoom >= _labelZoomThreshold)) {
      _currentZoom = newZoom;
      _buildMarkers();
    } else {
      _currentZoom = newZoom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // Full screen map behind everything
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _bucharestCenter,
                zoom: 13.5,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController!.setMapStyle(_darkMapStyle);
              },
              onCameraMove: _onCameraMove,
              onTap: (_) {
                setState(() {
                  _selectedRestaurant = null;
                });
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
            ),
          ),

          // Draggable bottom sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _collapsedSize,
            minChildSize: _collapsedSize,
            maxChildSize: _expandedSize,
            snap: true,
            snapSizes: const [_collapsedSize, _expandedSize],
            builder: (context, scrollController) {
              return _buildSheet(scrollController);
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F0F0F),
                    const Color(0xFF0F0F0F).withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Restaurants near you",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Restaurant count badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${_restaurants.length} restaurants",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Selected restaurant popup
          if (_selectedRestaurant != null)
            Positioned(
              bottom: MediaQuery.of(context).size.height * _collapsedSize + 16,
              left: 16,
              right: 16,
              child: _buildRestaurantPopup(_selectedRestaurant!),
            ),
        ],
      ),
    );
  }

  Widget _buildSheet(ScrollController scrollController) {
    return AnimatedBuilder(
      animation: _sheetController,
      builder: (context, child) {
        // Progress 0 = collapsed, 1 = expanded
        final double progress = _sheetController.isAttached
            ? ((_sheetController.size - _collapsedSize) /
                    (_expandedSize - _collapsedSize))
                .clamp(0.0, 1.0)
            : 0.0;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle + header — always visible
              SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 14),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Title + View all
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "New on DINEO",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, '/restaurants'),
                            child: const Text(
                              "View all →",
                              style: TextStyle(
                                color: Color(0xFFB71C1C),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Horizontal cards list
                    SizedBox(
                      height: _cardHeight(progress),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _restaurants.length,
                        itemBuilder: (context, index) {
                          return _buildCard(
                              _restaurants[index], progress);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Card height grows as sheet expands
  double _cardHeight(double progress) {
    const double collapsed = 110.0;
    const double expanded = 180.0;
    return collapsed + (expanded - collapsed) * progress;
  }

  Widget _buildCard(Map<String, dynamic> r, double progress) {
    return GestureDetector(
      onTap: () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(r["lat"], r["lng"]),
            16.0,
          ),
        );
        setState(() {
          _selectedRestaurant = r;
        });
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating — always visible
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFB71C1C).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star,
                      color: Color(0xFFB71C1C), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    r["rating"].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Name — always visible
            Text(
              r["name"],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Cuisine type — fades in as sheet expands
            if (progress > 0.3) ...[
              const SizedBox(height: 4),
              Opacity(
                opacity: ((progress - 0.3) / 0.7).clamp(0.0, 1.0),
                child: Text(
                  r["cuisineType"],
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 11,
                  ),
                ),
              ),
            ],

            // Description — fades in when almost fully expanded
            if (progress > 0.6) ...[
              const SizedBox(height: 6),
              Opacity(
                opacity: ((progress - 0.6) / 0.4).clamp(0.0, 1.0),
                child: Text(
                  r["description"],
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 10,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantPopup(Map<String, dynamic> restaurant) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant["name"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant["cuisineType"],
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFB71C1C).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFB71C1C), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        restaurant["rating"].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/restaurants');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "View Restaurant",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
  {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#bdbdbd"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#181818"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
  {"featureType": "poi.park", "elementType": "labels.text.stroke", "stylers": [{"color": "#1b1b1b"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#373737"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3c3c3c"}]},
  {"featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [{"color": "#4e4e4e"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d3d3d"}]}
]
''';