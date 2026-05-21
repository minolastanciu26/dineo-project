import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  String _firstName = '';
  String _lastName = '';
  String _phone = '';
  String _email = '';
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('firstName') ?? '';
      _lastName = prefs.getString('lastName') ?? '';
      _phone = prefs.getString('userPhone') ?? '';
      _email = prefs.getString('userEmail') ?? '';
      final imagePath = prefs.getString('profileImagePath');
      if (imagePath != null) {
        _profileImage = File(imagePath);
      }
    });
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Profile Picture",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFB71C1C)),
              title: const Text("Choose from Gallery", style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('profileImagePath', image.path);
                  setState(() => _profileImage = File(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFB71C1C)),
              title: const Text("Take a Photo", style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('profileImagePath', image.path);
                  setState(() => _profileImage = File(image.path));
                }
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Remove Photo", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('profileImagePath');
                  setState(() => _profileImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String field, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF262626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter $field",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF333333),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _editName() async {
    final firstController = TextEditingController(text: _firstName);
    final lastController = TextEditingController(text: _lastName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF262626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Edit Name",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "First Name",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF333333),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: lastController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Last Name",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF333333),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('firstName', firstController.text.trim());
              await prefs.setString('lastName', lastController.text.trim());
              setState(() {
                _firstName = firstController.text.trim();
                _lastName = lastController.text.trim();
              });
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                Image.asset('assets/images/logo.png', height: 30),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Poza de profil
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF332020),
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person_outline, size: 55, color: Color(0xFFB71C1C))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFB71C1C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: const Text(
              "Add a profile picture",
              style: TextStyle(color: Color(0xFFB71C1C), fontSize: 14),
            ),
          ),
          const SizedBox(height: 40),

          // Informații utilizator
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF321E1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    value: '$_firstName $_lastName'.trim().isEmpty
                        ? 'No name'
                        : '$_firstName $_lastName',
                    onEdit: _editName,
                  ),
                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    value: _phone.isEmpty ? 'No phone number' : _phone,
                    onEdit: () => _showEditDialog('Phone Number', _phone, (val) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('userPhone', val);
                      setState(() => _phone = val);
                    }),
                  ),
                  _buildInfoTile(
                    icon: Icons.email_outlined,
                    value: _email.isEmpty ? 'No email' : _email,
                    onEdit: () => _showEditDialog('Email', _email, (val) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('userEmail', val);
                      setState(() => _email = val);
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String value,
    required VoidCallback onEdit,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 3.5),
      leading: Icon(icon, color: const Color(0xFFB71C1C), size: 28),
      title: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: TextButton(
        onPressed: onEdit,
        child: const Text(
          "edit",
          style: TextStyle(color: Color(0xFFB71C1C), fontSize: 14),
        ),
      ),
      shape: const Border(bottom: BorderSide(color: Colors.white10, width: 0.8)),
    );
  }
}