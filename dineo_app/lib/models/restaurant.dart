class Restaurant {
  final int id;
  final String name;
  final String? description;
  final String? cuisineType;
  final double rating;
  final String? address;
  final String? imageUrl;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.cuisineType,
    required this.rating,
    this.address,
    this.imageUrl,
    this.phoneNumber,
    this.latitude,
    this.longitude,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      cuisineType: json['cuisineType'],
      rating: (json['rating'] as num).toDouble(),
      address: json['address'],
      imageUrl: json['imageUrl'],
      phoneNumber: json['phoneNumber'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}