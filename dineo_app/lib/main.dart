import 'package:dineo_app/screens/login_screen.dart';
import 'package:dineo_app/screens/onboarding/onboarding_screen.dart';
import 'package:dineo_app/screens/onboarding/welcome_screen.dart';
import 'package:dineo_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'models/restaurant.dart';
import 'services/api_service.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home/homepage_screen.dart';
import 'screens/profile_screen.dart'; // Crează acest fișier

void main() {
  runApp(const DineoApp());
}

class DineoApp extends StatelessWidget {
  const DineoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DINEO',
      // Setează pagina de start
      initialRoute: '/', 
      // Definirea rutelor
      routes: {
        '/': (context) => WelcomeScreen(), // Pagina de start
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomepageScreen(),
        '/profile': (context) => ProfileScreen(), // Trebuie să creezi acest fișier
        '/map': (context) => MapViewScreen(),    // Trebuie să creezi acest fișier
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Restaurant>> futureRestaurants;

  @override
  void initState() {
    super.initState();
    futureRestaurants = apiService.getRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DINEO - Explore'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nu am găsit restaurante.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var restaurant = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.all(10),
                color: const Color(0xFF1E1E1E),
                child: ListTile(
                  leading: const Icon(Icons.restaurant, color: Colors.orange),
                  title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${restaurant.cuisineType} • ${restaurant.description}"),
                  trailing: Text("${restaurant.rating} ⭐", style: const TextStyle(color: Colors.orange)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}