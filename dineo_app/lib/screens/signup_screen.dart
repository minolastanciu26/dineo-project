import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io'; // Import obligatoriu pentru Platform.isAndroid

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Controllere pentru toate câmpurile din Figma
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Funcție utilă pentru a crea câmpurile de text rapid (reusable)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isPasswordShown = true,
    VoidCallback? toggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordShown,
        keyboardType: keyboardType,
        autocorrect: false, // Fără autocorecție
        enableSuggestions: false, // Fără sugestii
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordShown ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', height: 40),
              const SizedBox(height: 30),
              
              const Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 28, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField(controller: _firstNameController, hint: "First Name"),
              _buildTextField(controller: _lastNameController, hint: "Last Name"),
              _buildTextField(
                controller: _emailController, 
                hint: "Email", 
                keyboardType: TextInputType.emailAddress
              ),
              _buildTextField(
                controller: _phoneController, 
                hint: "Phone Number", 
                keyboardType: TextInputType.phone
              ),
              _buildTextField(
                controller: _passwordController,
                hint: "Password",
                isPassword: true,
                isPasswordShown: _passwordVisible,
                toggleVisibility: () => setState(() => _passwordVisible = !_passwordVisible),
              ),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: "Confirm Password",
                isPassword: true,
                isPasswordShown: _confirmPasswordVisible,
                toggleVisibility: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),

              const SizedBox(height: 30),

              // Butonul Sign Up
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final firstName = _firstNameController.text.trim();
                    final lastName = _lastNameController.text.trim();
                    final email = _emailController.text.trim();
                    final phone = _phoneController.text.trim();
                    final password = _passwordController.text;
                    final confirmPassword = _confirmPasswordController.text;

                    // 1. Validări
                    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Te rugăm să completezi câmpurile obligatorii!")),
                      );
                      return;
                    }

                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Parolele nu coincid!")),
                      );
                      return;
                    }

                    // --- LOGICA DE IP UNIVERSAL ---
                    String baseUrl = Platform.isAndroid ? 'http://10.0.2.2:5177' : 'http://127.0.0.1:5177';
                    final url = Uri.parse('$baseUrl/api/auth/register');
                    // ------------------------------

                    try {
                      final response = await http.post(
                        url,
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "firstName": firstName,
                          "lastName": lastName,
                          "email": email,
                          "phoneNumber": phone,
                          "password": password,
                        }),
                      );

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cont creat cu succes! Te poți loga.")),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Eroare la creare: ${response.body}")),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Nu mă pot conecta la server.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),

              const SizedBox(height: 20),
              const Text("- Or -", style: TextStyle(color: Colors.grey, fontSize: 20)),
              const SizedBox(height: 20),

              // Google Sign Up
              OutlinedButton(
                onPressed: () {
                   print("Sign Up with Google apăsat");
                },
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
                    const Text("Sign Up with Google", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}