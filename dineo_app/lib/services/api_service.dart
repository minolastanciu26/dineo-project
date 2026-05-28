import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import 'dart:io';

class ApiService {
  String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:5177";
    } else {
      return "http://127.0.0.1:5177";
    }
  }

  Future<List<Restaurant>> getRestaurants({String? search}) async {
    final uri = search != null && search.isNotEmpty
        ? Uri.parse('$baseUrl/api/restaurants?search=$search')
        : Uri.parse('$baseUrl/api/restaurants');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Restaurant.fromJson(item)).toList();
    } else {
      throw Exception("Error loading restaurants");
    }
  }

  Future<List<Restaurant>> getTopRated() async {
    final response = await http.get(Uri.parse('$baseUrl/api/restaurants/top-rated'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Restaurant.fromJson(item)).toList();
    } else {
      throw Exception("Error loading restaurants");
    }
  }

  Future<List<Restaurant>> getNewRestaurants() async {
    final response = await http.get(Uri.parse('$baseUrl/api/restaurants/new'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Restaurant.fromJson(item)).toList();
    } else {
      throw Exception("Error loading restaurants");
    }
  }

  Future<Restaurant> getRestaurantById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/restaurants/$id'));
    if (response.statusCode == 200) {
      return Restaurant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Restaurant not found");
    }
  }

  Future<bool> checkFavourite(int userId, int restaurantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/favourites/$userId/check/$restaurantId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['isFavourite'];
    }
    return false;
  }

  Future<void> addFavourite(int userId, int restaurantId) async {
    await http.post(
      Uri.parse('$baseUrl/api/favourites'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "restaurantId": restaurantId}),
    );
  }

  Future<void> removeFavourite(int userId, int restaurantId) async {
    final request = http.Request('DELETE', Uri.parse('$baseUrl/api/favourites'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({"userId": userId, "restaurantId": restaurantId});
    await request.send();
  }

  Future<List<Restaurant>> getFavouriteRestaurants(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/favourites/$userId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Restaurant.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> checkFavouriteItem(int userId, int menuItemId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/favouriteitems/$userId/check/$menuItemId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['isFavourite'];
    }
    return false;
  }

  Future<void> addFavouriteItem(int userId, int menuItemId) async {
    await http.post(
      Uri.parse('$baseUrl/api/favouriteitems'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "menuItemId": menuItemId}),
    );
  }

  Future<void> removeFavouriteItem(int userId, int menuItemId) async {
    final request = http.Request('DELETE', Uri.parse('$baseUrl/api/favouriteitems'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({"userId": userId, "menuItemId": menuItemId});
    await request.send();
  }

  Future<List<MenuItem>> getFavouriteItems(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/favouriteitems/$userId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => MenuItem.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<MenuItem>> getFavouriteItemsByRestaurant(int userId, int restaurantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/favouriteitems/$userId/restaurant/$restaurantId'),
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => MenuItem.fromJson(item)).toList();
    }
    return [];
  }

  // ── RESERVATIONS ─────────────────────────────────────
  Future<List<dynamic>> getAvailableTables(int restaurantId, DateTime date, String time) async {
    final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final uri = Uri.parse(
      '$baseUrl/api/reservations/available/$restaurantId?date=$formattedDate&time=$time:00',
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> createReservation({
    required int userId,
    required int restaurantId,
    required int tableId,
    required DateTime date,
    required String time,
    required int guestCount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reservations'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "restaurantId": restaurantId,
        "tableId": tableId,
        "date": date.toIso8601String(),
        "time": time,
        "guestCount": guestCount,
      }),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getUserReservations(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reservations/user/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // ── AI RECOMMEND ─────────────────────────────────────
  Future<String> getRecommendation(String preference) async {
  print('DEBUG: Calling recommend API at $baseUrl/api/recommend');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/recommend'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"preference": preference}),
    );
    print('DEBUG: Response status: ${response.statusCode}');
    print('DEBUG: Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['recommendation'] ?? 'No recommendation found.';
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  } catch (e) {
    print('DEBUG: Exception: $e');
    throw Exception("Error getting recommendation");
  }
}

// ── REVIEWS ──────────────────────────────────────────
Future<List<dynamic>> getReviews(int restaurantId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/reviews/restaurant/$restaurantId'),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  return [];
}

Future<Map<String, dynamic>> getAverageRating(int restaurantId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/reviews/restaurant/$restaurantId/average'),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  return {'average': 0.0, 'count': 0};
}

Future<bool> createReview({
  required int userId,
  required int restaurantId,
  required int rating,
  String? comment,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/reviews'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "userId": userId,
      "restaurantId": restaurantId,
      "rating": rating,
      "comment": comment,
    }),
  );
  return response.statusCode == 200;
}

// ── DISCOVERED ────────────────────────────────────────
Future<Map<String, dynamic>> getDiscovered(int userId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/discovered/$userId'),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  return {
    'allRestaurants': [],
    'discoveredCount': 0,
    'totalCount': 0,
    'percentage': 0.0
  };
}

}