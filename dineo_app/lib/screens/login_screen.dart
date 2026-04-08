import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Variabilă pentru a controla vizibilitatea parolei
  bool _passwordVisible = false; 

  // Controller-ele pentru a citi ce scrie utilizatorul în căsuțe
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fundalul închis din Figma
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80), 

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
              const SizedBox(height: 80),

              // 3. Input Email
              TextField(
                keyboardType: TextInputType.emailAddress, 
                controller: _emailController,
                autocorrect: false, 
                enableSuggestions: false, 
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
                obscureText: !_passwordVisible, 
                autocorrect: false,
                enableSuggestions: false,
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
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
              ), 
              const SizedBox(height: 50),

              // 5. Buton Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text;

                    bool emailValid = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(email);

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Te rugăm să completezi toate câmpurile!")),
                      );
                      return;
                    }

                    if (!emailValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Te rugăm să introduci un email valid!")),
                      );
                      return;
                    }

                    final url = Uri.parse('http://127.0.0.1:5177/api/auth/login');

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
                        print("SUCCES: ${data['message']}");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Te-ai logat cu succes!")),
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

              const Text("- or -", style: TextStyle(color: Colors.grey, fontSize: 20)),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png', 
                      height: 24, 
                    ),
                    const SizedBox(width: 12), // Spațiul necesar între iconiță și text
                    const Text(
                      "Continue with Google", 
                      style: TextStyle(color: Colors.white, fontSize: 16)
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
                  GestureDetector(
                    onTap: () {
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
              const SizedBox(height: 40), // Mai mult spațiu la final
            ],
          ),
        ),
      ),
    );
  }
}