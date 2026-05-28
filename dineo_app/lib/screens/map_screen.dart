import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  final double? targetLat;
  final double? targetLng;
  final String? targetName;
  final int? targetRestaurantId;

  const MapScreen({
    super.key,
    this.targetLat,
    this.targetLng,
    this.targetName,
    this.targetRestaurantId,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final ApiService _apiService = ApiService();
  Set<Marker> _markers = {};
  List<Restaurant> _restaurants = [];
  Restaurant? _selectedRestaurant;
  bool _isLoading = true;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const double _collapsedSize = 0.25;
  static const double _expandedSize = 0.55;

  static const LatLng _bucharestCenter = LatLng(44.4268, 26.1025);

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await _apiService.getRestaurants();
      setState(() {
        _restaurants = restaurants
            .where((r) => r.latitude != null && r.longitude != null)
            .toList();
        _isLoading = false;
      });
      await _buildMarkers();

      if (widget.targetRestaurantId != null) {
        final targets = _restaurants.where(
          (r) => r.id == widget.targetRestaurantId,
        ).toList();

        if (targets.isNotEmpty) {
          final target = targets.first;
          setState(() => _selectedRestaurant = target);
          await _buildMarkers();

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(const Duration(milliseconds: 500));
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(target.latitude!, target.longitude!),
                  zoom: 16,
                  tilt: 0,
                ),
              ),
            );
            _sheetController.animateTo(
              _expandedSize,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buildMarkers() async {
    final Set<Marker> markers = {};

    for (final r in _restaurants) {
      if (r.latitude == null || r.longitude == null) continue;

      final isSelected = _selectedRestaurant?.id == r.id;

      markers.add(
        Marker(
          markerId: MarkerId(r.id.toString()),
          position: LatLng(r.latitude!, r.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: r.name,
            snippet: r.cuisineType,
          ),
          onTap: () {
            setState(() => _selectedRestaurant = r);
            _buildMarkers();
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(r.latitude!, r.longitude!),
                16,
              ),
            );
            _sheetController.animateTo(
              _expandedSize,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
        ),
      );
    }

    if (mounted) setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // Full screen map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.targetLat != null
                    ? LatLng(widget.targetLat!, widget.targetLng!)
                    : _bucharestCenter,
                zoom: widget.targetLat != null ? 16 : 13.5,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController!.setMapStyle(_darkMapStyle);
              },
              onTap: (_) {
                setState(() => _selectedRestaurant = null);
                _buildMarkers();
                _sheetController.animateTo(
                  _collapsedSize,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: false,
            ),
          ),

          // Bottom sheet
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
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Color(0xFFB71C1C), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "${_restaurants.length} restaurants",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheet(ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                ),
              )
            else if (_selectedRestaurant != null)
              _buildSelectedRestaurant()
            else
              _buildRestaurantList(),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedRestaurant() {
    final r = _selectedRestaurant!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                r.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: const Color(0xFF2A2A2A),
                  child: const Icon(Icons.restaurant, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      r.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.cuisineType != null) ...[
            const SizedBox(height: 4),
            Text(
              r.cuisineType!,
              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
            ),
          ],
          if (r.address != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    r.address!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Widget _buildRestaurantList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Restaurants near you",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _restaurants.length,
              itemBuilder: (context, index) {
                final r = _restaurants[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedRestaurant = r);
                    _buildMarkers();
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(r.latitude!, r.longitude!),
                        16,
                      ),
                    );
                    _sheetController.animateTo(
                      _expandedSize,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: r.imageUrl != null
                              ? Image.network(
                                  r.imageUrl!,
                                  height: 90,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 90,
                                    color: const Color(0xFF333333),
                                    child: const Icon(Icons.restaurant,
                                        color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  height: 90,
                                  color: const Color(0xFF333333),
                                  child: const Icon(Icons.restaurant,
                                      color: Colors.grey),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Color(0xFFB71C1C), size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    r.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                r.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1a1a2e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8a8a9a"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a1a2e"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#3a3a5c"}]},
  {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9eb8"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#c5c5e0"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757585"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1e2a1e"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#4a6a4a"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c44"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9a9ab4"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#38384e"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#484860"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1a1a2e"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#636375"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#757585"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0d1b2a"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d6e8a"}]},
  {"featureType": "landscape", "elementType": "geometry", "stylers": [{"color": "#1e1e30"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry", "stylers": [{"color": "#252538"}]}
]
''';