import 'package:dineo_app/screens/login_screen.dart';
import 'package:dineo_app/screens/personal_info_screen.dart';
import 'package:dineo_app/screens/favourite_restaurants_screen.dart';
import 'package:dineo_app/screens/my_reservations_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'discovered_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = '';
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final firstName = prefs.getString('firstName') ?? '';
      final lastName = prefs.getString('lastName') ?? '';
      _fullName = '$firstName $lastName'.trim();
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Image.asset('assets/images/logo.png', height: 35),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF332020),
                    child: Icon(Icons.person_outline, size: 55, color: Color(0xFFB71C1C)),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _fullName.isEmpty ? 'Loading...' : _fullName,
                    style: const TextStyle(
                      color: Color(0xFFF6F6F6),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSettingsGroup(
                    context: context,
                    color: const Color(0xFF321E1E),
                    borderRadius: BorderRadius.circular(25),
                    options: [
                      _buildProfileOption(
                        Icons.person_outline,
                        "Personal Info",
                        context,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                        ),
                      ),
                      _buildProfileOption(
                        Icons.favorite_border,
                        "My Favourites",
                        context,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FavouriteRestaurantsScreen(userId: _userId),
                          ),
                        ),
                      ),
                      _buildProfileOption(
                        Icons.calendar_today_outlined,
                        "My Calendar",
                        context,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
                        ),
                      ),
                      _buildProfileOption(
  Icons.explore_outlined,
  "Discovered",
  context,
  () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const DiscoveredScreen()),
  ),
),
                      _buildProfileOption(Icons.payment_outlined, "Payment Methods", context, () {}),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          _buildSettingsGroup(
            context: context,
            color: const Color(0xFF262626),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            isBottom: true,
            options: [
              _buildProfileOption(
                Icons.logout,
                "Log Out",
                context,
                () => _showLogoutDialog(context),
              ),
              _buildProfileOption(
                Icons.delete_outline,
                "Delete Account",
                context,
                () => _showDeleteAccountDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required BuildContext context,
    required Color color,
    required BorderRadius borderRadius,
    required List<Widget> options,
    bool isBottom = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      padding: EdgeInsets.only(
        top: 15,
        bottom: isBottom ? MediaQuery.of(context).padding.bottom + 15 : 15,
      ),
      child: Column(children: options),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title,
    BuildContext context,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 3.5),
      leading: Icon(icon, color: const Color(0xFFB71C1C), size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
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
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("NO", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("YES", style: TextStyle(color: Color(0xFFB71C1C))),
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete your account? This action is permanent and all your data will be lost.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
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
              style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}