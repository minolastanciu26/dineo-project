class Restaurant {
  final int id;
  final String name;
  final String description;
  final String cuisineType;
  final double rating;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisineType,
    required this.rating,
  });

  // Transformă JSON-ul de la C# (Backend) în obiect Dart (Frontend)
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      cuisineType: json['cuisineType'] ?? '',
      rating: (json['rating'] as num).toDouble(),
    );
  }
}