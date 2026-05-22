import 'menu_item.dart';

class MenuCategory {
  final int id;
  final int restaurantId;
  final String name;
  final List<MenuItem> menuItems;

  MenuCategory({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.menuItems,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'],
      restaurantId: json['restaurantId'],
      name: json['name'] ?? '',
      menuItems: json['menuItems'] != null
          ? (json['menuItems'] as List).map((i) => MenuItem.fromJson(i)).toList()
          : [],
    );
  }
}

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
  final List<MenuCategory> menuCategories;

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
    this.menuCategories = const [],
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
      menuCategories: json['menuCategories'] != null
          ? (json['menuCategories'] as List)
              .map((c) => MenuCategory.fromJson(c))
              .toList()
          : [],
    );
  }
}