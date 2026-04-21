import 'package:dineo_app/screens/signup_screen.dart';
import 'package:dineo_app/screens/profile_screen.dart'; // Importă pagina de profil
import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'dart:io'; 
import 'package:shared_preferences/shared_preferences.dart'; // Corectat calea importului

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _passwordVisible = false; 

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80), 
              Image.asset('assets/images/logo.png', height: 50),
              const SizedBox(height: 50),
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 32, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 80),

              // Email Input
              TextField(
                keyboardType: TextInputType.emailAddress, 
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Email",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF333333),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), 
                    borderSide: BorderSide.none
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible, 
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF333333),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
              ), 
              const SizedBox(height: 50),

              // Buton Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text;

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Te rugăm să completezi toate câmpurile!")),
                      );
                      return;
                    }

                    String baseUrl = Platform.isAndroid ? 'http://10.0.2.2:5177' : 'http://127.0.0.1:5177';
                    final url = Uri.parse('$baseUrl/api/auth/login');

                    try {
                      final response = await http.post(
                        url,
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "email": email,
                          "password": password,
                        }),
                      );

                      if (response.statusCode == 200) {
                        final data = jsonDecode(response.body);

                        // 1. Inițializăm SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        
                        // 2. Salvăm ID-ul (verifică dacă cheia din backend e 'userId' sau 'id')
                        await prefs.setInt('userId', data['userId'] ?? 0); 
                        await prefs.setString('userEmail', email);

                        if (!mounted) return;

                        // 3. Afișăm mesaj și Navigăm
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Te-ai logat cu succes!")),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Email sau parolă incorectă!")),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Serverul Dineo este offline.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 30),
              const Text("- or -", style: TextStyle(color: Colors.grey, fontSize: 20)),
              const SizedBox(height: 30),

              // Google Login
              OutlinedButton(
                onPressed: () => print("Google Login apăsat"),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/google_logo.png', height: 24),
                    const SizedBox(width: 12), 
                    const Text("Continue with Google", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Navigare spre Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: Colors.white)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }
}