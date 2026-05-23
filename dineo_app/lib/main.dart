import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dineo_app/screens/onboarding/welcome_screen.dart';
import 'package:dineo_app/screens/login_screen.dart';
import 'package:dineo_app/screens/home/homepage_screen.dart';
import 'package:dineo_app/screens/profile_screen.dart';
import 'package:dineo_app/screens/recommend_screen.dart';
import 'package:dineo_app/screens/map_screen.dart';
import 'package:dineo_app/screens/restaurants_screen.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const DineoApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
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
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomepageScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/map': (context) => const MapScreen(),
        '/restaurants': (context) => const RestaurantsScreen(),
      },
    );
  }
}