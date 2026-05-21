import 'package:flutter/material.dart';
import 'package:dineo_app/screens/onboarding/welcome_screen.dart';
import 'package:dineo_app/screens/login_screen.dart';
import 'package:dineo_app/screens/home/homepage_screen.dart';
import 'package:dineo_app/screens/profile_screen.dart';
import 'dart:io';

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
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomepageScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/map': (context) => const MapViewScreen(),
      },
    );
  }
}