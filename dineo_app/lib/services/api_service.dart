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

  // ── AUTH ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return null;
  }

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── RESTAURANTS ───────────────────────────────────────

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
    final response =
        await http.get(Uri.parse('$baseUrl/api/restaurants/top-rated'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Restaurant.fromJson(item)).toList();
    } else {
      throw Exception("Error loading top rated restaurants");
    }
  }

  Future<List<Restaurant>> getNewRestaurants() async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/restaurants/new'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Restaurant.fromJson(item)).toList();
    } else {
      throw Exception("Error loading new restaurants");
    }
  }

  Future<Restaurant?> getRestaurantById(int id) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/restaurants/$id'));
      if (response.statusCode == 200) {
        return Restaurant.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  // ── FAVOURITES ────────────────────────────────────────

  Future<bool> checkFavourite(int userId, int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/favourites/$userId/check/$restaurantId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['isFavourite'] ?? false;
      }
    } catch (_) {}
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
    final request =
        http.Request('DELETE', Uri.parse('$baseUrl/api/favourites'));
    request.headers['Content-Type'] = 'application/json';
    request.body =
        jsonEncode({"userId": userId, "restaurantId": restaurantId});
    await request.send();
  }

  Future<List<Restaurant>> getFavouriteRestaurants(int userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/favourites/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Restaurant.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> checkFavouriteItem(int userId, int menuItemId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/favouriteitems/$userId/check/$menuItemId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['isFavourite'] ?? false;
      }
    } catch (_) {}
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
    final request =
        http.Request('DELETE', Uri.parse('$baseUrl/api/favouriteitems'));
    request.headers['Content-Type'] = 'application/json';
    request.body =
        jsonEncode({"userId": userId, "menuItemId": menuItemId});
    await request.send();
  }

  Future<List<MenuItem>> getFavouriteItems(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/favouriteitems/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => MenuItem.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<MenuItem>> getFavouriteItemsByRestaurant(
      int userId, int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/favouriteitems/$userId/restaurant/$restaurantId'),
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => MenuItem.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── RESERVATIONS ──────────────────────────────────────

  Future<List<dynamic>> getAvailableTables(
      int restaurantId, DateTime date, String time) async {
    try {
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final uri = Uri.parse(
        '$baseUrl/api/reservations/available/$restaurantId?date=$formattedDate&time=$time:00',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getFloorDecors(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/floordecor/restaurant/$restaurantId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
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
    try {
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
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getUserReservations(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reservations/user/$userId'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return [];
  }

  // ── AI RECOMMEND ──────────────────────────────────────

  Future<Map<String, dynamic>> getRecommendation(String preference) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/recommend'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"preference": preference}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting recommendation");
    }
  }

  // ── REVIEWS ───────────────────────────────────────────

  Future<List<dynamic>> getReviews(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/restaurant/$restaurantId'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> getAverageRating(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/reviews/restaurant/$restaurantId/average'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return {'average': 0.0, 'count': 0};
  }

  Future<bool> createReview({
    required int userId,
    required int restaurantId,
    required int rating,
    String? comment,
  }) async {
    try {
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
    } catch (_) {
      return false;
    }
  }

  // ── DISCOVERED ────────────────────────────────────────

  Future<Map<String, dynamic>> getDiscovered(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/discovered/$userId'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return {
      'allRestaurants': [],
      'discoveredCount': 0,
      'totalCount': 0,
      'percentage': 0.0
    };
  }

  // ── MONTHLY OFFER ─────────────────────────────────────

  Future<Map<String, dynamic>?> getCurrentOffer() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/monthlyoffer/current'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getUserOfferStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/monthlyoffer/user/$userId/status'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return null;
  }

  Future<bool> useMonthlyOffer(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/monthlyoffer/use'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── NOTIFICATIONS ─────────────────────────────────────

  Future<List<dynamic>> getNotifications(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/$userId'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return [];
  }

  Future<int> getUnreadCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/$userId/unread'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['count'] as int;
      }
    } catch (_) {}
    return 0;
  }

  Future<bool> markNotificationAsRead(int id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/$id/read'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead(int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/readall/$userId'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/$id'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createNotification({
    required int userId,
    required String title,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "title": title,
          "message": message,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // ORDERS & PAYMENTS  (feature/payments)
  // ════════════════════════════════════════════════════════

  // ── Reservation arrival check ──────────────────────────

  /// Call on app launch — sends "Your table is ready!" notification
  /// for reservations starting within the next 15 minutes.
  Future<void> checkReservationArrivals(int userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/reservationarrival/check'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'userId': userId}),
      );
    } catch (_) {}
  }

  // ── Orders ────────────────────────────────────────────

  /// Creates a new order or returns existing one for this reservation.
  /// Returns {'orderId': int} on success, null on failure.
  Future<Map<String, dynamic>?> createOrGetOrder({
    required int userId,
    required int restaurantId,
    required int reservationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userId': userId,
          'restaurantId': restaurantId,
          'reservationId': reservationId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'orderId': data['id']};
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getOrderByReservation(
      int reservationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/reservation/$reservationId'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getActiveOrderForUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/user/$userId/active'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> getRecommendations(int userId, {int take = 8}) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/recommendations/$userId?take=$take'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  } catch (e) {
    return [];
  }
}

  Future<void> addItemToOrder({
    required int orderId,
    required int menuItemId,
    required int quantity,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/orders/$orderId/items'),
        headers: {"Content-Type": "application/json"},
        body:
            jsonEncode({'menuItemId': menuItemId, 'quantity': quantity}),
      );
    } catch (_) {}
  }

  Future<void> updateOrderItem({
    required int orderId,
    required int itemId,
    required int quantity,
  }) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/items/$itemId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'quantity': quantity}),
      );
    } catch (_) {}
  }

  Future<void> removeOrderItem(
      {required int orderId, required int itemId}) async {
    try {
      await http.delete(
          Uri.parse('$baseUrl/api/orders/$orderId/items/$itemId'));
    } catch (_) {}
  }

  Future<void> updateOrderStatus(
      {required int orderId, required String status}) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'status': status}),
      );
    } catch (_) {}
  }

  Future<void> requestBill({
    required int orderId,
    required String paymentMethod,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/orders/$orderId/request-bill'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'paymentMethod': paymentMethod}),
      );
    } catch (_) {}
  }

  Future<bool> payWithCard({required int orderId}) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/api/orders/$orderId/pay-card'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}