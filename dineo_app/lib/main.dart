import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dineo_app/screens/onboarding/welcome_screen.dart';
import 'package:dineo_app/screens/login_screen.dart';
import 'package:dineo_app/screens/home/homepage_screen.dart';
import 'package:dineo_app/screens/profile_screen.dart';
import 'package:dineo_app/screens/restaurants_screen.dart';
import 'package:dineo_app/screens/map_screen.dart';
import 'package:dineo_app/screens/reviews_screen.dart';
import 'package:dineo_app/providers/cart_provider.dart';
import 'dart:io';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const DineoApp(),
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class DineoApp extends StatelessWidget {
  const DineoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DINEO',
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomepageScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/map': (context) => const MapScreen(),
        '/restaurants': (context) => const RestaurantsScreen(),
      },
      onGenerateRoute: (settings) {
  final uri = Uri.parse(settings.name ?? '');
  if (uri.pathSegments.length == 3 &&
      uri.pathSegments[0] == 'restaurant' &&
      uri.pathSegments[2] == 'review') {
    final restaurantId = int.tryParse(uri.pathSegments[1]) ?? 0;
    final args = settings.arguments as Map<String, dynamic>?;
    return MaterialPageRoute(
      builder: (_) => ReviewsScreen(
        restaurantId: restaurantId,
        restaurantName: args?['restaurantName'] as String? ?? '',
        userId: args?['userId'] as int? ?? 0,
      ),
    );
  }
  return null;
},
    );
  }
}