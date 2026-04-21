import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';

class ApiService {
  // ATENȚIE: Dacă rulezi în Chrome, folosim 'localhost'. 
  // Portul 7042 este cel din imaginea ta de la Swagger.
  // Șterge linia veche cu 7042 și pune asta:
  final String baseUrl = "http://127.0.0.1:5177/api";

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