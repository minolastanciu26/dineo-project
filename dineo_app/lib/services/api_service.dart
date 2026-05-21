import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import 'dart:io'; // <--- Added this line

class ApiService {
  // Automatically detects if it's running on Android Emulator or iOS/Mac
  String get baseUrl {
    if (Platform.isAndroid) {
      return "http//10.0.2.2:7042"; // For Windows Android Emulator
    } else {
      return "http//127.0.0.1:7042"; // For Mac iOS Simulator / Web
    }
  }

  Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/restaurants'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Restaurant.fromJson(item)).toList();
      } else {
        throw Exception("Serverul a răspuns cu eroare: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Nu s-a putut face conexiunea: $e");
    }
  }
}