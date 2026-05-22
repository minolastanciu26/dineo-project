import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
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
      throw Exception("Eroare la încărcarea restaurantelor");
    }
  }

  Future<List<Restaurant>> getTopRated() async {
    final response = await http.get(Uri.parse('$baseUrl/api/restaurants/top-rated'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Restaurant.fromJson(item)).toList();
    } else {
      throw Exception("Eroare la încărcarea restaurantelor");
    }
  }

  Future<List<Restaurant>> getNewRestaurants() async {
    final response = await http.get(Uri.parse('$baseUrl/api/restaurants/new'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Restaurant.fromJson(item)).toList();
    } else {
      throw Exception("Eroare la încărcarea restaurantelor");
    }
  }

  Future<Restaurant> getRestaurantById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/restaurants/$id'));
    if (response.statusCode == 200) {
      return Restaurant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Restaurantul nu există");
    }
  }
}