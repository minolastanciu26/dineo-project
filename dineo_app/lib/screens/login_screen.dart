import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller-ele pentru a citi ce scrie utilizatorul
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fundalul închis din Figma
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Logo
            Image.asset(
              'assets/images/logo.png', 
              height: 50,
            ),
            const SizedBox(height: 50),
            
            // 2. Titlu
            const Text(
              "Welcome Back!",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 32, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 100), // Am ajustat de la 200 la 100 ca să fii sigur că încape totul

            // 3. Input Email
            TextField(
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

            // 4. Input Parolă
            TextField(
              controller: _passwordController,
              obscureText: true, // Ascunde caracterele pentru securitate
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Password",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF333333),
                suffixIcon: const Icon(Icons.visibility, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30), 
                  borderSide: BorderSide.none
                ),
              ),
            ),
            const SizedBox(height: 50),

            // 5. Buton Login
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Aici vom face legătura cu Backend-ul din Docker
                  print("Email: ${_emailController.text}");
                  print("Password: ${_passwordController.text}");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C), // Roșul Dineo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),
                ),
                child: const Text(
                  "LOGIN", 
                  style: TextStyle(color: Colors.white, fontSize: 18)
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Text("- Or -", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // 6. Continue with Google
            OutlinedButton(
              onPressed: () {
                print("Google Login apăsat");
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Text(
                    "Continue with Google", 
                    style: TextStyle(color: Colors.white)
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 7. Don't have an account? Sign Up
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: Colors.white),
              ),
              GestureDetector( // <--- Ăsta e widget-ul care "simte" atingerea
                onTap: () {    // <--- Atenție: la GestureDetector se folosește onTap, nu onPressed
                  print("Navigare către pagina de Sign Up");
                },
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Color(0xFFB71C1C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}
