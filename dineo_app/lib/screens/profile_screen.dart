import 'package:dineo_app/screens/login_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset('assets/images/logo.png', height: 35), // Logo ușor mai mare
                        ),
                        const SizedBox(height: 40),
                        const CircleAvatar(
                          radius: 50, // Mărit de la 45
                          backgroundColor: Color(0xFF332020),
                          child: Icon(Icons.person_outline, size: 55, color: Color(0xFFB71C1C)),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Minola Stanciu",
                          style: TextStyle(
                            color: Color(0xFFB71C1C),
                            fontSize: 24, // Mărit de la 22
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30), // Redus de la 40 ca să fie mai aproape

                  // 1. Containerul Roșiatic (Margine-n margine)
                  _buildSettingsGroup(
                    color: const Color(0xFF321E1E),
                    borderRadius: BorderRadius.circular(25),
                    options: [
                      _buildProfileOption(Icons.person_outline, "Personal Info", context, () {}),
                      _buildProfileOption(Icons.favorite_border, "My Favourites", context, () {}),
                      _buildProfileOption(Icons.calendar_today_outlined, "My Calendar", context, () {}),
                      _buildProfileOption(Icons.explore_outlined, "Discovered", context, () {}),
                      _buildProfileOption(Icons.payment_outlined, "Payment Methods", context, () {}),
                    ],
                  ),
                  const SizedBox(height: 15), // Spațiul mic dintre secțiuni cerut de tine
                ],
              ),
            ),
          ),

          // 2. Containerul Gri de Jos
          _buildSettingsGroup(
            color: const Color(0xFF262626),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25), // Mai rotunjit pentru aspect premium
              topRight: Radius.circular(25),
            ),
            isBottom: true,
            options: [
              _buildProfileOption(Icons.logout, "Log Out", context, () => _showLogoutDialog(context)),
              _buildProfileOption(Icons.delete_outline, "Delete Account", context, () {
                _showDeleteAccountDialog(context); // Apelează funcția de mai sus
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required Color color,
    required BorderRadius borderRadius,
    required List<Widget> options,
    bool isBottom = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      padding: EdgeInsets.only(
        top: 15, 
        bottom: isBottom ? 50 : 15 // Padding mai generos
      ),
      child: Column(children: options),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, BuildContext context, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 3.5), // Vertical mărește „înălțimea” rândului
      leading: Icon(icon, color: const Color(0xFFB71C1C), size: 28), // Iconițe mai mari
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 20, // Text mult mai mare (profi)
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFB71C1C), size: 30),
      onTap: onTap,
      shape: const Border(bottom: BorderSide(color: Colors.white10, width: 0.8)),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF262626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Log Out", style: TextStyle(color: Colors.white)),
        content: const Text("Sigur vrei să ieși din contul tău?", style: TextStyle(color: Colors.grey)),
        actions: [
          // Butonul NU doar închide fereastra
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("NU", style: TextStyle(color: Colors.grey))
          ),
          // Butonul DA te scoate de tot la Login
          TextButton(
            onPressed: () {
              // 1. Închidem dialogul
              Navigator.pop(context); 

              // 2. Navigăm la Login și ștergem tot istoricul de pagini (stack-ul)
              // Importă login_screen.dart dacă îți dă eroare pe LoginScreen()
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // Această condiție asigură că nu mai există cale de întoarcere
              );
            }, 
            child: const Text("DA", style: TextStyle(color: Color(0xFFB71C1C)))
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF262626),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Delete Account", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
      ),
      content: const Text(
        "Are you sure you want to delete your account? This action is permanent and all your data will be lost.",
        style: TextStyle(color: Colors.grey),
      ),
      actions: [
        // Butonul de anulare
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
        ),
        // Butonul de ștergere (Roșu aprins)
        TextButton(
          onPressed: () async {
            // 1. Închidem dialogul
            Navigator.pop(context);

            // AICI va veni cererea de tip DELETE către Backend-ul tău (Docker)
            // ex: http.delete(url, headers: ...)
            
            print("Cerere de ștergere cont trimisă către server...");

            // 2. După ce serverul confirmă ștergerea, trimitem userul la Login
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account deleted successfully.")),
            );
          },
          child: const Text(
            "DELETE", 
            style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)
          ),
        ),
      ],
    ),
  );
}
}