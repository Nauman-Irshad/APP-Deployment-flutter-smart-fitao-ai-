import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import 'chat.dart';
import '../core/navigation/app_navigation.dart';
import 'auth-login-sign/auth_storage.dart';
import 'privacy_legal_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isPressed = false;
  bool _loadingProfile = true;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isEditing = false;

  String _emailDisplay = '';

  final Color _greenColor = Color(0xFF2E7D32);
  final Color _brownColor = Color(0xFF795548);
  final Color _whiteColor = Colors.white;

  final AppBackend _backend = AppBackend.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
          _emailDisplay = '';
        });
      }
      return;
    }

    try {
      final profile = await _backend.getUserProfile(user.uid);
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('imagePath');
      if (!mounted) return;
      setState(() {
        _nameController.text = profile.name.isNotEmpty ? profile.name : (user.displayName ?? '');
        _addressController.text = profile.address;
        _emailDisplay = user.email ?? profile.email;
        _loadingProfile = false;
        if (imagePath != null && File(imagePath).existsSync()) {
          _image = File(imagePath);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nameController.text = user.displayName ?? '';
        _addressController.text = '';
        _emailDisplay = user.email ?? '';
        _loadingProfile = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    try {
      await _backend.updateUserProfileFields(
        uid: user.uid,
        name: name,
        address: address,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $e')),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (_image != null) {
      await prefs.setString('imagePath', _image!.path);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      setState(() => _isEditing = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 25.0),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _brownColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _greenColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
             borderSide: BorderSide(color: _brownColor.withOpacity(0.5)),
             borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 40),
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
           boxShadow: [
             BoxShadow(
               color: color.withOpacity(0.3),
               blurRadius: 8,
               offset: Offset(0, 4),
             )
           ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            SizedBox(width: 20),
            Icon(icon, color: _whiteColor),
            SizedBox(width: 15),
            Text(text, style: TextStyle(color: _whiteColor, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return Scaffold(
        backgroundColor: Color(0xFFF2F4F8),
        appBar: AppBar(
          title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: _whiteColor)),
          centerTitle: true,
          backgroundColor: _greenColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      floatingActionButton: null,
      backgroundColor: Color(0xFFF2F4F8), 
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: _whiteColor)),
        centerTitle: true,
        backgroundColor: _greenColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: _whiteColor),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: _greenColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                 children: [
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _whiteColor, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: _whiteColor,
                            backgroundImage: _image != null
                                ? FileImage(_image!)
                                : const AssetImage('assets/banner 1.png')
                                    as ImageProvider,
                          ),
                        ),
                        if (_isEditing)
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                               padding: EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: _brownColor,
                                 shape: BoxShape.circle,
                                 border: Border.all(color: _whiteColor, width: 2),
                               ),
                               child: Icon(Icons.camera_alt, color: _whiteColor, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      _nameController.text.isEmpty ? 'Your name' : _nameController.text,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _whiteColor),
                    ),
                    if (_emailDisplay.isNotEmpty)
                      Text(
                        _emailDisplay, 
                        style: TextStyle(fontSize: 14, color: _whiteColor.withOpacity(0.9)),
                      ),
                 ],
              ),
            ),
           
            SizedBox(height: 25),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildTextField("Full Name", _nameController),
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 25.0),
                     child: InputDecorator(
                       decoration: InputDecoration(
                         labelText: 'Email',
                         labelStyle: TextStyle(color: _brownColor),
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                         enabledBorder: OutlineInputBorder(
                           borderSide: BorderSide(color: _brownColor.withOpacity(0.5)),
                           borderRadius: BorderRadius.circular(12),
                         ),
                       ),
                       child: Padding(
                         padding: const EdgeInsets.symmetric(vertical: 4.0),
                         child: Text(
                           _emailDisplay.isEmpty ? '—' : _emailDisplay,
                           style: TextStyle(fontSize: 16, color: Colors.black87),
                         ),
                       ),
                     ),
                   ),
                   _buildTextField("Home Address", _addressController),
                ],
              ),
            ),

            SizedBox(height: 30),
            
            SizedBox(height: 40),
            Column(
              children: [

                _actionButton(context, "Chat with Seller", Icons.storefront, Color(0xFF171717), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()));
                }),
                   SizedBox(height: 10),
                  _actionButton(context, "Chat with Tailor", Icons.storefront, Color(0xFF059669), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()));
                }),
                SizedBox(height: 10),
                _actionButton(context, "Your Measurements", Icons.straighten, Color(0xFF059669), () { 
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Measurement Screen Coming Soon')));
                }),
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy & Legal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Terms, privacy policy, and how we protect your data',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _actionButton(
                  context,
                  "Privacy & Security",
                  Icons.shield_outlined,
                  const Color(0xFF1565C0),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyLegalScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _actionButton(
                  context,
                  "Privacy Policy",
                  Icons.privacy_tip_outlined,
                  const Color(0xFF5D4037),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyLegalScreen(
                          initialSection: PrivacyLegalSection.privacy,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _actionButton(
                  context,
                  "Terms of Service",
                  Icons.gavel_outlined,
                  const Color(0xFF455A64),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyLegalScreen(
                          initialSection: PrivacyLegalSection.terms,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) async {
                setState(() => _isPressed = false);
                await AppNavigation.logoutToRolePicker(context);
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedScale(
                scale: _isPressed ? 0.95 : 1.0,
                duration: Duration(milliseconds: 150),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 60, vertical: 25),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Logout",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


}
